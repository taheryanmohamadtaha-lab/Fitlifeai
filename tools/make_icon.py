# Generates the FitLife AI app icon (green gradient, white figure + leaf)
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import math, sys

S = 2048  # supersampled canvas

def bez(p0, p1, p2, p3, n=60):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = (1-t)**3*p0[0] + 3*(1-t)**2*t*p1[0] + 3*(1-t)*t**2*p2[0] + t**3*p3[0]
        y = (1-t)**3*p0[1] + 3*(1-t)**2*t*p1[1] + 3*(1-t)*t**2*p2[1] + t**3*p3[1]
        pts.append((x, y))
    return pts

OX, OY = 80, -90
def sc(pts, k):  # scale from design space (1100 units) with centering offset
    return [((x+OX)*k, (y+OY)*k) for x, y in pts]

def figure_layers(size, margin_scale=1.0):
    """Return (white_layer, leaf_layer) RGBA images, drawn in a 1000-unit space."""
    k = size / 1100.0
    white = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    leaf = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    dw = ImageDraw.Draw(white)
    dl = ImageDraw.Draw(leaf)

    # head
    cx, cy, r = 500, 330, 78
    dw.ellipse([(cx+OX-r)*k, (cy+OY-r)*k, (cx+OX+r)*k, (cy+OY+r)*k], fill=(255, 255, 255, 255))

    # body + arms (one smooth silhouette)
    left_arm = bez((170, 440), (260, 520), (380, 585), (500, 585))
    right_arm = bez((500, 585), (620, 585), (740, 520), (830, 440))
    arm_w = 34
    # arms as thick strokes
    dense = bez((170, 440), (260, 520), (380, 585), (500, 585), 400) + bez((500, 585), (620, 585), (740, 520), (830, 440), 400)
    for (x, y) in dense:
        dw.ellipse([(x+OX-arm_w)*k, (y+OY-arm_w)*k, (x+OX+arm_w)*k, (y+OY+arm_w)*k], fill=(255, 255, 255, 255))
    # torso wedge
    torso = bez((390, 560), (370, 700), (400, 820), (470, 905)) + \
            bez((470, 905), (500, 940), (540, 940), (560, 905))[1:] + \
            bez((560, 905), (610, 800), (640, 680), (610, 560))[1:]
    dw.polygon(sc(torso, k), fill=(255, 255, 255, 255))

    # crescent on the left (outer arc minus inner arc)
    outer = bez((205, 600), (110, 760), (150, 900), (330, 990), 80) + \
            bez((330, 990), (420, 1030), (480, 1030), (520, 1015), 40)[1:]
    inner = bez((520, 1015), (420, 985), (300, 940), (240, 840), 60) + \
            bez((240, 840), (205, 770), (200, 680), (205, 600), 40)[1:]
    dw.polygon(sc(outer + inner, k), fill=(255, 255, 255, 255))

    # leaf on the right
    leaf_poly = bez((470, 1015), (400, 940), (420, 800), (560, 740), 80) + \
                bez((560, 740), (640, 705), (700, 650), (715, 560), 80)[1:] + \
                bez((715, 560), (770, 700), (770, 880), (640, 985), 80)[1:] + \
                bez((640, 985), (590, 1025), (520, 1035), (470, 1015), 80)[1:]
    dl.polygon(sc(leaf_poly, k), fill=(196, 232, 130, 255))
    # leaf vein (darker green cut)
    vein = bez((480, 1005), (470, 900), (520, 810), (600, 780), 60)
    vd = bez((480, 1005), (470, 900), (520, 810), (600, 780), 300)
    for (x, y) in vd:
        dl.ellipse([(x+OX-9)*k, (y+OY-9)*k, (x+OX+9)*k, (y+OY+9)*k], fill=(120, 190, 90, 255))
    return white, leaf

def gradient(size, c1, c2):
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    t = (x + y) / (2.0 * (size - 1))
    t = t[..., None]
    a = np.array(c1, np.float32)
    b = np.array(c2, np.float32)
    img = a * (1 - t) + b * t
    return Image.fromarray(img.astype(np.uint8), "RGB").convert("RGBA")

def shadow(layer, blur, dy, alpha=90):
    a = layer.split()[3].point(lambda v: v * alpha // 255)
    sh = Image.new("RGBA", layer.size, (0, 40, 20, 0))
    sh.putalpha(a)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    out = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    out.paste(sh, (0, dy), sh)
    return out

def compose_figure(size, inset):
    """Figure on transparent, scaled by inset (1.0 = full canvas)."""
    white, leaf = figure_layers(size)
    fig = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fig = Image.alpha_composite(fig, shadow(white, size*0.012, int(size*0.012)))
    fig = Image.alpha_composite(fig, white)
    fig = Image.alpha_composite(fig, shadow(leaf, size*0.012, int(size*0.012)))
    fig = Image.alpha_composite(fig, leaf)
    if inset != 1.0:
        n = int(size * inset)
        small = fig.resize((n, n), Image.LANCZOS)
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        off = (size - n) // 2
        canvas.paste(small, (off, off), small)
        fig = canvas
    return fig

def main(out_dir):
    bg = gradient(S, (126, 217, 87), (11, 145, 115))
    # rounded square mask
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S-1, S-1], radius=int(S*0.22), fill=255)
    fig = compose_figure(S, 0.80)
    full = Image.alpha_composite(bg, fig)
    full.putalpha(mask)
    full.resize((1024, 1024), Image.LANCZOS).save(f"{out_dir}/icon.png")

    # adaptive icon foreground: figure inside the 66% safe zone
    fg = compose_figure(S, 0.56)
    fg.resize((1024, 1024), Image.LANCZOS).save(f"{out_dir}/icon_foreground.png")

if __name__ == "__main__":
    main(sys.argv[1])
