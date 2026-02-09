import { useEffect, useState } from "react";

const API = "http://a9a123590a4dc4c3ab287764656bb632-63322373.us-east-1.elb.amazonaws.com:5000/students";

function App() {
  const [students, setStudents] = useState([]);
  const [name, setName] = useState("");
  const [age, setAge] = useState("");

  const load = async () => {
    const res = await fetch(API);
    setStudents(await res.json());
  };

  const addStudent = async () => {
    await fetch(API, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, age })
    });
    setName("");
    setAge("");
    load();
  };

  const deleteStudent = async (id) => {
    await fetch(`${API}/${id}`, { method: "DELETE" });
    load();
  };

  useEffect(() => { load(); }, []);

  return (
    <div style={{ padding: 20 }}>
      <h2>Student Management</h2>

      <input value={name} onChange={e=>setName(e.target.value)} placeholder="Name"/>
      <input value={age} onChange={e=>setAge(e.target.value)} placeholder="Age"/>
      <button onClick={addStudent}>Add</button>

      <ul>
        {students.map(s => (
          <li key={s._id}>
            {s.name} ({s.age})
            <button onClick={() => deleteStudent(s._id)}>X</button>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
