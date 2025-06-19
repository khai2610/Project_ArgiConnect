const Provider = require('../../models/Provider');

exports.getAllApprovedProviders = async (req, res) => {
  try {
    const filter = { status: 'APPROVED' };

    if (req.query.service_type) {
      filter.service_types = req.query.service_type;
    }

    const providers = await Provider.find(filter).select('-password -__v');
    res.json(providers);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
