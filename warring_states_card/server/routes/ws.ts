import { createGameRoom, getGameState, updateGameState, endGame } from '../utils/database';

interface GameAction {
  type: 'play_card' | 'attack' | 'end_turn' | 'use_hero_power';
  odID: string;
  data?: any;
}

interface WebSocketMessage {
  type: 'join' | 'leave' | 'action' | 'sync' | 'ping' | 'pong';
  matchId?: string;
  odID?: string;
  action?: GameAction;
  data?: any;
}

interface ConnectedClient {
  odID: string;
  matchId?: string;
  ws: any;
}

// 管理连接的客户端
const clients = new Map<string, ConnectedClient>();

export default defineWebSocketHandler({
  open(ws) {
    console.log('WebSocket opened');
  },
  
  message(ws, message) {
    try {
      const msg: WebSocketMessage = JSON.parse(message.toString());
      handleMessage(ws, msg);
    } catch (e) {
      console.error('WebSocket message error:', e);
      ws.send(JSON.stringify({ error: 'Invalid message format' }));
    }
  },
  
  close(ws) {
    // 清理客户端连接
    for (const [odID, client] of clients) {
      if (client.ws === ws) {
        clients.delete(odID);
        
        // 离开匹配队列
        if (client.matchId) {
          leaveMatchQueue(odID);
        }
        
        break;
      }
    }
  },
  
  error(ws, error) {
    console.error('WebSocket error:', error);
  },
});

async function handleMessage(ws: any, msg: WebSocketMessage) {
  switch (msg.type) {
    case 'ping':
      ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
      break;
      
    case 'join':
      // 加入游戏房间
      if (!msg.matchId || !msg.odID) {
        ws.send(JSON.stringify({ error: 'Missing matchId or odID' }));
        return;
      }
      
      const room = await getGameState(msg.matchId);
      if (!room) {
        ws.send(JSON.stringify({ error: 'Room not found' }));
        return;
      }
      
      const player = room.players.find((p: any) => p.odID === msg.odID);
      if (!player) {
        ws.send(JSON.stringify({ error: 'Player not in room' }));
        return;
      }
      
      clients.set(msg.odID, { odID: msg.odID, matchId: msg.matchId, ws });
      ws.send(JSON.stringify({ 
        type: 'joined', 
        matchId: msg.matchId,
        players: room.players,
        state: room.state,
      }));
      
      // 广播给对手
      broadcastToOpponent(msg.matchId, msg.odID, { type: 'opponent_joined', odID: msg.odID });
      break;
      
    case 'leave':
      if (msg.odID) {
        clients.delete(msg.odID);
      }
      ws.close();
      break;
      
    case 'action':
      if (!msg.matchId || !msg.action) {
        ws.send(JSON.stringify({ error: 'Missing matchId or action' }));
        return;
      }
      
      // 处理游戏动作
      const newState = await processGameAction(msg.matchId, msg.action);
      
      // 广播给所有玩家
      broadcastToRoom(msg.matchId, { 
        type: 'action_result', 
        action: msg.action,
        state: newState,
        timestamp: Date.now(),
      });
      
      // 检查游戏是否结束
      if (newState?.phase === 'ended') {
        if (newState.winnerOdID) {
          await endGame(msg.matchId, newState.winnerOdID);
        }
        broadcastToRoom(msg.matchId, { 
          type: 'game_ended', 
          winnerOdID: newState.winnerOdID,
        });
      }
      break;
      
    case 'sync':
      if (msg.matchId) {
        const state = await getGameState(msg.matchId);
        ws.send(JSON.stringify({ type: 'sync_result', state }));
      }
      break;
  }
}

async function processGameAction(matchId: string, action: GameAction): Promise<any> {
  const room = await getGameState(matchId);
  if (!room) return null;
  
  // 获取当前游戏状态
  let state = room.state || {
    phase: 'playing',
    turn: room.players[0].odID,
    players: {
      [room.players[0].odID]: { health: 30, mana: 1, maxMana: 1, hand: [], board: [] },
      [room.players[1].odID]: { health: 30, mana: 1, maxMana: 1, hand: [], board: [] },
    },
  };
  
  // 处理动作
  switch (action.type) {
    case 'play_card':
      // 出牌逻辑
      break;
    case 'attack':
      // 攻击逻辑
      break;
    case 'end_turn':
      // 结束回合
      state.turn = state.turn === room.players[0].odID ? room.players[1].odID : room.players[0].odID;
      break;
    case 'use_hero_power':
      // 使用英雄技能
      break;
  }
  
  // 更新状态
  await updateGameState(matchId, state);
  return state;
}

function broadcastToOpponent(matchId: string, excludeOdID: string, message: any) {
  const msgStr = JSON.stringify(message);
  
  for (const client of clients.values()) {
    if (client.matchId === matchId && client.odID !== excludeOdID) {
      client.ws.send(msgStr);
    }
  }
}

function broadcastToRoom(matchId: string, message: any) {
  const msgStr = JSON.stringify(message);
  
  for (const client of clients.values()) {
    if (client.matchId === matchId) {
      client.ws.send(msgStr);
    }
  }
}

function leaveMatchQueue(odID: string) {
  // 从匹配队列中移除
  // 这个需要在database.ts中实现
}

// 定期清理超时连接
setInterval(() => {
  const now = Date.now();
  for (const [odID, client] of clients) {
    // 如果连接超时未响应，关闭它
    // 这里可以实现心跳检测
  }
}, 60000);