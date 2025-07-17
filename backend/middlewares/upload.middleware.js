const multer = require('multer');
const path = require('path');

// Cấu hình nơi lưu trữ và tên file
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/avatars/');
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    cb(null, `${req.user.id}-${Date.now()}${ext}`);
  }
});

// Lọc loại file
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) cb(null, true);
  else cb(new Error('Chỉ chấp nhận file ảnh'), false);
};

const upload = multer({ storage, fileFilter });

module.exports = upload;
