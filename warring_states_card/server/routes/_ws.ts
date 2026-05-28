import { WebSocketServer, WebSocket } from 'ws';
import { prisma, getRedis, verifyToken } from '../utils/database';

// 游戏房间管理
interface GameRoom {
  id: string;
  player1Id: string;
  player2Id: string;
  ws1: WebSocket;
  ws2: WebSocket;
  state: GameState;
  createdAt: Date;
}

interface GameState {
  player1Hand: string[];
  player2Hand: string[];
  player1Board: any[];
  player2Board: any[];
  player1Health: number;
  player2Health: number;
  player1Mana: number;
  player2Mana: number;
  currentTurn: number;
  activePlayer: number;
}

// WebSocket连接管理
const rooms = new Map<string, GameRoom>();
const playerConnections = new Map<string, WebSocket>();

export function setupWebSocket(server: any) {
  const wss = new WebSocketServer({ server });
  
  wss.on('connection', async (ws, req) => {
    // 解析token
    const url = new URL(req.url || '', 'http://localhost');
    const token = url.searchParams.get('token');
    
    if (!token) {
      ws.close(4001, 'Missing token');
      return;
    }
    
    const payload = verifyToken(token);
    if (!payload) {
      ws.close(4002, 'Invalid token');
      return;
    }
    
    const { playerId } = payload;
    playerConnections.set(playerId, ws);
    
    console.log(`Player ${playerId} connected`);
    
    // 处理消息
    ws.on('message', async (data) => {
      try {
        const message = JSON.parse(data.toString());
        await handleMessage(ws, playerId, message);
      } catch (error) {
        console.error('WebSocket message error:', error);
        ws.send(JSON.stringify({ type: 'error', message: 'Invalid message format' }));
      }
    });
    
    // 断开连接
    ws.on('close', () => {
      playerConnections.delete(playerId);
      
      // 清理房间
      for (const [roomId, room] of rooms) {
        if (room.player1Id === playerId || room.player2Id === playerId) {
          // 通知对方断开
          const otherWs = room.player1Id === playerId ? room.ws2 : room.ws1;
          otherWs?.send(JSON.stringify({ type: 'opponent_disconnected' }));
          rooms.delete(roomId);
        }
      }
    });
  });
  
  return wss;
}

async function handleMessage(ws: WebSocket, playerId: string, message: any) {
  const { type, data } = message;
  
  switch (type) {
    case 'matchmaking_join':
      await joinMatchmaking(ws, playerId);
      break;
      
    case 'matchmaking_leave':
      await leaveMatchmaking(playerId);
      break;
      
    case 'play_card':
      await playCard(playerId, data);
      break;
      
    case 'attack':
      await attack(playerId, data);
      break;
      
    case 'end_turn':
      await endTurn(playerId);
      break;
      
    case 'hero_power':
      await useHeroPower(playerId, data);
      break;
      
    case 'concede':
      await concede(playerId);
      break;
  }
}

// 加入匹配队列
async function joinMatchmaking(ws: WebSocket, playerId: string) {
  const redis = await getRedis();
  
  // 查找等待中的对手
  const waitingPlayerId = await redis.lPop('matchmaking_queue');
  
  if (waitingPlayerId && waitingPlayerId !== playerId) {
    // 找到对手，创建房间
    const roomId = crypto.randomUUID();
    const opponentWs = playerConnections.get(waitingPlayerId);
    
    if (opponentWs?.readyState === WebSocket.OPEN) {
      // 创建游戏房间
      const room: GameRoom = {
        id: roomId,
        player1Id: waitingPlayerId,
        player2Id: playerId,
        ws1: opponentWs,
        ws2: ws,
        state: initGameState(),
        createdAt: new Date(),
      };
      rooms.set(roomId, room);
      
      // 通知双方
      opponentWs.send(JSON.stringify({
        type: 'match_found',
        data: { roomId, isPlayer1: true },
      }));
      ws.send(JSON.stringify({
        type: 'match_found',
        data: { roomId, isPlayer1: false },
      }));
      
      return;
    }
  }
  
  // 没有对手，加入等待队列
  await redis.rPush('matchmaking_queue', playerId);
  ws.send(JSON.stringify({ type: 'matchmaking_waiting' }));
  
  // 30秒超时
  setTimeout(async () => {
    const stillWaiting = await redis.lRange('matchmaking_queue', 0, -1);
    if (stillWaiting.includes(playerId)) {
      await redis.lRem('matchmaking_queue', 1, playerId);
      ws.send(JSON.stringify({ type: 'matchmaking_timeout' }));
    }
  }, 30000);
}

// 离开匹配队列
async function leaveMatchmaking(playerId: string) {
  const redis = await getRedis();
  await redis.lRem('matchmaking_queue', 1, playerId);
}

// 初始化游戏状态
function initGameState(): GameState {
  return {
    player1Hand: [],
    player2Hand: [],
    player1Board: [],
    player2Board: [],
    player1Health: 30,
    player2Health: 30,
    player1Mana: 1,
    player2Mana: 1,
    currentTurn: 1,
    activePlayer: 1,
  };
}

// 出牌
async function playCard(playerId: string, data: { roomId: string; cardIndex: number }) {
  const room = rooms.get(data.roomId);
  if (!room) return;
  
  const isPlayer1 = room.player1Id === playerId;
  const { cardIndex } = data;
  
  // 获取手牌
  const hand = isPlayer1 ? room.state.player1Hand : room.state.player2Hand;
  if (cardIndex < 0 || cardIndex >= hand.length) return;
  
  const cardId = hand[cardIndex];
  
  // 更新状态
  if (isPlayer1) {
    room.state.player1Hand.splice(cardIndex, 1);
    room.state.player1Mana -= 1; // 实际应计算费用
  } else {
    room.state.player2Hand.splice(cardIndex, 1);
    room.state.player2Mana -= 1;
  }
  
  // 广播给双方
  broadcastToRoom(room, {
    type: 'card_played',
    data: { playerId, cardId, isPlayer1 },
  });
}

// 攻击
async function attack(playerId: string, data: { roomId: string; attackerIndex: number; targetIndex: number }) {
  const room = rooms.get(data.roomId);
  if (!room) return;
  
  broadcastToRoom(room, {
    type: 'attack',
    data: { ...data, playerId },
  });
}

// 结束回合
async function endTurn(playerId: string) {
  for (const [roomId, room] of rooms) {
    if (room.player1Id === playerId || room.player2Id === playerId) {
      room.state.currentTurn++;
      room.state.activePlayer = room.player1Id === playerId ? 2 : 1;
      
      // 恢复法力
      if (room.state.activePlayer === 1) {
        room.state.player1Mana = Math.min(10, room.state.player1Mana + 1);
      } else {
        room.state.player2Mana = Math.min(10, room.state.player2Mana + 1);
      }
      
      broadcastToRoom(room, {
        type: 'turn_end',
        data: { nextPlayer: room.player1Id === playerId ? room.player2Id : room.player1Id },
      });
      break;
    }
  }
}

// 使用英雄技能
async function useHeroPower(playerId: string, data: { roomId: string; targetId?: string }) {
  const room = rooms.get(data.roomId);
  if (!room) return;
  
  broadcastToRoom(room, {
    type: 'hero_power_used',
    data: { playerId, targetId: data.targetId },
  });
}

// 投降
async function concede(playerId: string) {
  for (const [roomId, room] of rooms) {
    if (room.player1Id === playerId || room.player2Id === playerId) {
      const winnerId = room.player1Id === playerId ? room.player2Id : room.player1Id;
      
      // 记录战绩
      await prisma.match.create({
        data: {
          playerId: room.player1Id,
          opponentId: room.player2Id,
          winnerId,
          turns: room.state.currentTurn,
          isRanked: true,
        },
      });
      
      broadcastToRoom(room, { type: 'game_over', data: { winnerId } });
      rooms.delete(roomId);
      break;
    }
  }
}

// 广播给房间内所有玩家
function broadcastToRoom(room: GameRoom, message: any) {
  if (room.ws1.readyState === WebSocket.OPEN) {
    room.ws1.send(JSON.stringify(message));
  }
  if (room.ws2.readyState === WebSocket.OPEN) {
    room.ws2.send(JSON.stringify(message));
  }
}