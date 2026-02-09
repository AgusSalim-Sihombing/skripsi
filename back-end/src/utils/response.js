const success = (res, data = null, message = "Success", code = 200) => {
  res.status(code).json({
    status: "success",
    message,
    data,
  });
};

const error = (res, message = "Error", code = 500) => {
  res.status(code).json({
    status: "error",
    message,
  });
};

module.exports = { success, error };
