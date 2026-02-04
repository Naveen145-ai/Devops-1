const express = require("express");
const mongoose = require("mongoose");
const app = express();

app.use(express.json());

// MongoDB connection
mongoose.connect(process.env.MONGO_URL)
  .then(() => console.log("MongoDB connected"))
  .catch(err => console.log(err));

// Schema
const StudentSchema = new mongoose.Schema({
  name: String,
  age: Number
});

const Student = mongoose.model("Student", StudentSchema);

// CREATE
app.post("/students", async (req, res) => {
  const student = await Student.create(req.body);
  res.json(student);
});

// READ
app.get("/students", async (req, res) => {
  const students = await Student.find();
  res.json(students);
});

// UPDATE
app.put("/students/:id", async (req, res) => {
  const student = await Student.findByIdAndUpdate(
    req.params.id,
    req.body,
    { new: true }
  );
  res.json(student);
});

// DELETE
app.delete("/students/:id", async (req, res) => {
  await Student.findByIdAndDelete(req.params.id);
  res.send("Deleted");
});

app.listen(5000, () => console.log("Backend running on 5000"));
