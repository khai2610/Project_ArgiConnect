const Provider = require('../../models/Provider');

// GET /api/provider/services
exports.getServices = async (req, res) => {
  const provider = await Provider.findById(req.user.id).select('services');
  res.json(provider.services);
};

// POST /api/provider/services
exports.addService = async (req, res) => {
  const { name, description, price, unit } = req.body;

  if (!name || name.trim() === '') {
    return res.status(400).json({ message: 'Tên dịch vụ là bắt buộc' });
  }

  const provider = await Provider.findById(req.user.id);
  if (!provider) return res.status(404).json({ message: 'Không tìm thấy provider' });

  const exists = provider.services.some(s => s.name === name);
  if (exists) return res.status(400).json({ message: 'Dịch vụ đã tồn tại' });

  provider.services.push({
    name,
    description,
    price: price ?? 0,
    unit: unit || 'VNĐ/ha'
  });

  await provider.save();
  res.status(201).json({ message: 'Thêm dịch vụ thành công', services: provider.services });
};

// DELETE /api/provider/services/:name
exports.removeService = async (req, res) => {
  const name = req.params.name;

  const provider = await Provider.findById(req.user.id);
  if (!provider) return res.status(404).json({ message: 'Không tìm thấy provider' });

  const before = provider.services.length;
  provider.services = provider.services.filter(s => s.name !== name);

  if (provider.services.length === before) {
    return res.status(404).json({ message: 'Không tìm thấy dịch vụ cần xoá' });
  }

  await provider.save();
  res.json({ message: 'Xoá dịch vụ thành công', services: provider.services });
};

  // PATCH /api/provider/services/:name
exports.updateService = async (req, res) => {
  try {
    const provider = await Provider.findById(req.user.id);
    if (!provider) return res.status(404).json({ message: 'Không tìm thấy provider' });

    const serviceName = req.params.name;
    const { description, price, unit } = req.body;

    const service = provider.services.find(s => s.name === serviceName);
    if (!service) {
      return res.status(404).json({ message: 'Không tìm thấy dịch vụ cần cập nhật' });
    }

    if (description !== undefined) service.description = description;
    if (price !== undefined) service.price = price;
    if (unit !== undefined) service.unit = unit;

    await provider.save();
    res.json({ message: 'Cập nhật dịch vụ thành công', service });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
