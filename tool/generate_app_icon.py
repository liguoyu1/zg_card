"""Generate 1024x1024 app icon for Warring States Card"""
from PIL import Image, ImageDraw, ImageFont
import math, os

SIZE = 1024
OUT = 'assets/app_icon.png'  # base icon for flutter_launcher_icons

def draw_icon():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Dark gradient background
    for y in range(SIZE):
        t = y / SIZE
        r = int(30 + t * 40)
        g = int(15 + t * 25)
        b = int(8 + t * 12)
        draw.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))

    # Outer border (golden)
    bm = 20  # border margin
    for i in range(4):  # multiple passes for thickness
        off = bm + i
        draw.rectangle([off, off, SIZE - off, SIZE - off],
                        outline=(212, 175, 55, 255), width=4)

    # Inner decorative border
    im = 50
    for i in range(2):
        off = im + i * 3
        draw.rectangle([off, off, SIZE - off, SIZE - off],
                        outline=(180, 140, 40, 180), width=2)

    # Corner ornaments
    cr = 80  # corner radius
    for cx, cy in [(cr, cr), (SIZE - cr, cr), (cr, SIZE - cr), (SIZE - cr, SIZE - cr)]:
        # Diamond pattern
        s = 30
        draw.polygon([(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)],
                      fill=(212, 175, 55, 200))
        # Small circle in center
        draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(255, 215, 0, 220))

    # Center: shield/card shape
    shield_cx = SIZE // 2
    shield_cy = SIZE // 2 - 20
    sw, sh = 340, 400

    # Shield/card shape
    shield_pts = [
        (shield_cx - sw // 2, shield_cy - sh // 2 + 40),
        (shield_cx + sw // 2, shield_cy - sh // 2 + 40),
        (shield_cx + sw // 2, shield_cy + sh // 2 - 60),
        (shield_cx + sw // 4, shield_cy + sh // 2),
        (shield_cx, shield_cy + sh // 2 + 20),
        (shield_cx - sw // 4, shield_cy + sh // 2),
        (shield_cx - sw // 2, shield_cy + sh // 2 - 60),
    ]
    draw.polygon(shield_pts, fill=(60, 30, 10, 230), outline=(212, 175, 55, 220), width=4)

    # Inner shield fill
    inner_pts = [(p[0], p[1] + 5) for p in shield_pts[1:]]
    inner_pts.insert(0, shield_pts[0])
    draw.polygon(inner_pts, fill=(80, 35, 8, 200),
                  outline=(180, 140, 40, 160), width=2)

    # Cross swords behind shield
    for sx, sy, rot in [(shield_cx - 50, shield_cy + 10, -30),
                         (shield_cx + 50, shield_cy + 10, 30)]:
        # Sword shaft
        draw.rectangle([sx - 4, sy - 180, sx + 4, sy + 60],
                        fill=(180, 180, 180, 200))
        # Sword guard
        draw.rectangle([sx - 18, sy - 20, sx + 18, sy - 8],
                        fill=(212, 175, 55, 200))
        # Sword blade
        draw.polygon([(sx - 4, sy - 180), (sx + 4, sy - 180),
                       (sx + 4, sy - 80), (sx, sy - 70),
                       (sx - 4, sy - 80)],
                      fill=(200, 200, 210, 200))
        # Pommel
        draw.ellipse([sx - 6, sy + 55, sx + 6, sy + 70],
                      fill=(212, 175, 55, 200))

    # Center character: 战 (war)
    # Simple stylized "战" with geometric shapes
    ch = 100  # character half-size
    # Left side (⻊)
    # Draw a simplified character pattern
    draw.rectangle([shield_cx - ch - 30, shield_cy - ch,
                     shield_cx - ch + 10, shield_cy + ch],
                    fill=(212, 175, 55, 220), width=3)
    # Right side (戈) - simplified
    draw.rectangle([shield_cx - ch + 20, shield_cy - ch + 20,
                     shield_cx + ch, shield_cy - ch + 30],
                    fill=(212, 175, 55, 220), width=3)

    # Instead, draw a simple ornate circular emblem at center
    # Golden disk
    r = 80
    draw.ellipse([shield_cx - r, shield_cy - r, shield_cx + r, shield_cy + r],
                  fill=None, outline=(212, 175, 55, 220), width=6)
    draw.ellipse([shield_cx - r - 6, shield_cy - r - 6,
                   shield_cx + r + 6, shield_cy + r + 6],
                  fill=None, outline=(180, 140, 40, 120), width=2)
    # Inner star/diamond
    star_r = 40
    for i in range(4):
        a = math.pi / 2 * i + math.pi / 4
        x1 = shield_cx + int(star_r * math.cos(a))
        y1 = shield_cy + int(star_r * math.sin(a))
        a2 = a + math.pi / 4
        x2 = shield_cx + int(star_r * 0.4 * math.cos(a2))
        y2 = shield_cy + int(star_r * 0.4 * math.sin(a2))
        draw.line([(shield_cx, shield_cy), (x1, y1)],
                   fill=(255, 215, 0, 220), width=4)

    # Bottom text bar
    by = SIZE - 140
    # Semi-transparent bar
    draw.rectangle([200, by, SIZE - 200, by + 70],
                    fill=(0, 0, 0, 160), outline=(212, 175, 55, 150), width=2)

    return img

def main():
    os.makedirs('assets', exist_ok=True)
    img = draw_icon()
    img.save(OUT, 'PNG')
    print(f'✅ Icon saved: {OUT} ({os.path.getsize(OUT)//1024}KB)')
    # Also copy to favicon location
    favicon = img.resize((48, 48), Image.LANCZOS)
    favicon.save('web/favicon.png', 'PNG')
    print(f'✅ Favicon updated: web/favicon.png')

if __name__ == '__main__':
    main()
