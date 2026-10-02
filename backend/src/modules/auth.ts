import { Hono } from "hono";
import { sign, verify } from "hono/jwt";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { prisma } from "../db.js";

const JWT_SECRET = process.env.JWT_SECRET || "toko-susilawati-secret-jwt-key-2026";

export const authRouter = new Hono();

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

authRouter.post("/login", zValidator("json", loginSchema), async (c) => {
  const { email, password } = c.req.valid("json");

  const user = await prisma.user.findUnique({
    where: { email },
    include: { store: true },
  });

  if (!user || !user.isActive) {
    return c.json({ error: "Email atau kata sandi salah" }, 401);
  }

  const isValid = await Bun.password.verify(password, user.passwordHash);
  if (!isValid) {
    return c.json({ error: "Email atau kata sandi salah" }, 401);
  }

  await prisma.user.update({
    where: { id: user.id },
    data: { lastLoginAt: new Date() },
  });

  const payload = {
    sub: user.id,
    storeId: user.storeId,
    role: user.role,
    name: user.name,
    email: user.email,
    exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 7, // 7 days
  };

  const token = await sign(payload, JWT_SECRET);

  return c.json({
    token,
    user: {
      id: user.id,
      storeId: user.storeId,
      storeName: user.store.name,
      name: user.name,
      email: user.email,
      role: user.role,
    },
  });
});

authRouter.get("/me", async (c) => {
  const authHeader = c.req.header("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return c.json({ error: "Akses tidak diizinkan" }, 401);
  }

  const token = authHeader.replace("Bearer ", "");
  try {
    const payload = await verify(token, JWT_SECRET, "HS256");
    const user = await prisma.user.findUnique({
      where: { id: payload.sub as string },
      include: { store: true },
    });

    if (!user || !user.isActive) {
      return c.json({ error: "Pengguna tidak aktif" }, 401);
    }

    return c.json({
      user: {
        id: user.id,
        storeId: user.storeId,
        storeName: user.store.name,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  } catch {
    return c.json({ error: "Token kadaluarsa atau tidak valid" }, 401);
  }
});

// Middleware for protected routes
export async function requireAuth(c: any, next: any) {
  const authHeader = c.req.header("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return c.json({ error: "Akses tidak diizinkan, silakan login" }, 401);
  }

  const token = authHeader.replace("Bearer ", "");
  try {
    const payload = await verify(token, JWT_SECRET, "HS256");
    c.set("user", payload);
    c.set("storeId", payload.storeId);
    await next();
  } catch {
    return c.json({ error: "Token tidak valid" }, 401);
  }
}
