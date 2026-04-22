import React from "react";
import ReactDOM from "react-dom/client";
import "./styles.css";

function App() {
  const [tasks, setTasks] = React.useState([]);
  const [title, setTitle] = React.useState("");
  const [description, setDescription] = React.useState("");
  const [loading, setLoading] = React.useState(true);
  const [saving, setSaving] = React.useState(false);
  const [error, setError] = React.useState("");

  async function loadTasks() {
    setLoading(true);
    setError("");

    try {
      const response = await fetch("/api/tasks");
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || "Failed to load tasks");
      }

      setTasks(data.tasks || []);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  React.useEffect(() => {
    loadTasks();
  }, []);

  async function createTask(event) {
    event.preventDefault();
    setSaving(true);
    setError("");

    try {
      const response = await fetch("/api/tasks", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ title, description }),
      });
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || "Failed to create task");
      }

      setTasks((current) => [data.task, ...current]);
      setTitle("");
      setDescription("");
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  }

  async function toggleTask(task) {
    setError("");

    try {
      const response = await fetch(`/api/tasks/${task.id}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ is_done: !task.is_done }),
      });
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || "Failed to update task");
      }

      setTasks((current) =>
        current.map((item) => (item.id === task.id ? data.task : item))
      );
    } catch (err) {
      setError(err.message);
    }
  }

  async function removeTask(id) {
    setError("");

    try {
      const response = await fetch(`/api/tasks/${id}`, {
        method: "DELETE",
      });
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || "Failed to delete task");
      }

      setTasks((current) => current.filter((item) => item.id !== id));
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <main className="app-shell">
      <section className="hero-card">
        <div className="header-row">
          <div>
            <p className="eyebrow">Day 1 Goal</p>
            <h1>TaskApp</h1>
            <p className="summary">
              React frontend, PHP API, and PostgreSQL wired together as a small task manager.
            </p>
          </div>
          <a className="action secondary" href="/api/health" target="_blank" rel="noreferrer">
            API health
          </a>
        </div>

        <form className="task-form" onSubmit={createTask}>
          <label>
            Title
            <input
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              placeholder="Add a task title"
              required
            />
          </label>
          <label>
            Description
            <textarea
              value={description}
              onChange={(event) => setDescription(event.target.value)}
              placeholder="Optional detail"
              rows="3"
            />
          </label>
          <button className="action" type="submit" disabled={saving}>
            {saving ? "Saving..." : "Create task"}
          </button>
        </form>

        {error ? <p className="status error">{error}</p> : null}
        {loading ? <p className="status">Loading tasks...</p> : null}

        <div className="task-list">
          {tasks.length === 0 && !loading ? (
            <p className="status">No tasks yet. Create your first one.</p>
          ) : null}

          {tasks.map((task) => (
            <article className="task-card" key={task.id}>
              <div>
                <h2 className={task.is_done ? "done" : ""}>{task.title}</h2>
                <p>{task.description || "No description provided."}</p>
              </div>
              <div className="task-actions">
                <button className="ghost" onClick={() => toggleTask(task)}>
                  {task.is_done ? "Mark open" : "Mark done"}
                </button>
                <button className="ghost danger" onClick={() => removeTask(task.id)}>
                  Delete
                </button>
              </div>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
