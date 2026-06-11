const express = require("express");
const multer  = require("multer");
const cors    = require("cors");
const path    = require("path");

const app  = express();
const PORT = 3000;

// ── CORS 허용 ────────────────────────────────────────────────
app.use(cors());

// ── 정적 파일 서빙 (index.html, uploads/) ───────────────────
app.use(express.static(__dirname));
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// ── Multer 설정 (파일 저장 위치 및 이름) ────────────────────
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "uploads"));
  },
  filename: (req, file, cb) => {
    const ext  = path.extname(file.originalname);
    const name = Date.now() + "-" + Math.round(Math.random() * 1e6) + ext;
    cb(null, name);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 최대 10MB
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|gif|webp/;
    const ok = allowed.test(path.extname(file.originalname).toLowerCase())
            && allowed.test(file.mimetype);
    ok ? cb(null, true) : cb(new Error("이미지 파일만 업로드 가능합니다."));
  }
});

// ── 업로드 엔드포인트 ────────────────────────────────────────
app.post("/upload", upload.single("nftImage"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "파일이 없습니다." });
  }
  const fileUrl = `http://localhost:${PORT}/uploads/${req.file.filename}`;
  console.log(`[업로드] ${req.file.originalname} → ${fileUrl}`);
  res.json({ url: fileUrl, filename: req.file.filename });
});

// ── 서버 시작 ────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`✅ 서버 실행 중: http://localhost:${PORT}`);
  console.log(`📁 업로드 폴더: ${path.join(__dirname, "uploads")}`);
});
