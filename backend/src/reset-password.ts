// Pakai: NEW_PASSWORD='...' bun src/reset-password.ts [email]
import { prisma } from "./db.js";

const pw = process.env.NEW_PASSWORD;
if (!pw || pw.length < 8) throw new Error("NEW_PASSWORD wajib diisi (min 8 karakter)");
const email = process.argv[2] ?? "owner@susilawati.com";

const r = await prisma.user.updateMany({
  where: { email },
  data: { passwordHash: await Bun.password.hash(pw, { algorithm: "argon2id" }), isActive: true },
});
console.log(r.count ? `Password ${email} diperbarui` : `User ${email} tidak ditemukan`);
await prisma.$disconnect();
