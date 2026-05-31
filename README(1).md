# 👑 Quiz of Queen

A terminal-based two-player trivia game inspired by the popular mobile game *Quiz of Kings*. Built with Python and PostgreSQL, it lets players go head-to-head across six knowledge categories with a full XP system, leaderboards, and an admin panel for managing users and questions.

---

## 📋 Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [How to Play](#how-to-play)
- [User Roles](#user-roles)
- [XP & Scoring System](#xp--scoring-system)
- [Admin Features](#admin-features)

---

## ✨ Features

- **Two-Player Matches** — Challenge a specific player or get matched with a random active user
- **6 Knowledge Categories** — History, Movie, Music, Sport, Foods, Geography
- **3 Difficulty Levels** — Easy, Medium, Hard (each with an XP multiplier)
- **5 Rounds per Game** — Each player answers 3 questions per round (60-second time limit per question)
- **XP & Leaderboards** — Earn XP based on performance; climb the overall and weekly rankings
- **Question Submission** — Any active user can submit questions; admins approve or reject them
- **Admin Panel** — Approve/reject questions and manage user account status
- **Secure Authentication** — Passwords are hashed with bcrypt; login supports both username and email
- **Player Profiles** — View stats (total games, wins, losses, XP, rank) for any user
- **Category Stats** — See which categories are played the most

---

## 📁 Project Structure

```
QuizOfQueen/
├── src/
│   ├── client/
│   │   └── main.py                   # Entry point & main menu
│   ├── controllers/
│   │   ├── SignInSignUp.py           # Authentication (login & registration)
│   │   ├── PlayGame.py               # Core game loop
│   │   ├── AddQuestion.py            # Question submission
│   │   ├── ShowQuestionsToApproved.py# Admin: question approval
│   │   ├── BlockUser.py              # Admin: activate/deactivate users
│   │   ├── PlayerStatusTable.py      # Player profile viewer
│   │   ├── ShowTotalTable.py         # Overall leaderboard
│   │   ├── weekstatus.py             # Weekly leaderboard
│   │   └── CategoryTable.py          # Most-played categories
│   ├── DataBase/
│   │   └── DataBase.py               # PostgreSQL connection helper
│   └── model/
│       ├── Question.py               # Question data model
│       └── PlayerStatus.py           # Player stats data model
├── DB_backup.sql                     # Full PostgreSQL database dump
├── ER_model.png                      # Entity-Relationship diagram
└── README.md
```

---

## 🗃️ Database Schema

The database is hosted on PostgreSQL and contains the following tables:

| Table | Description |
|---|---|
| `users` | Stores accounts (username, email, hashed password, status) |
| `questions` | All trivia questions with options, correct answer, difficulty, and approval status |
| `categories` | The 6 categories with a `mostplayed` counter |
| `gamesessions` | Records of each match (players, start/end time, winner) |
| `rounds` | Individual rounds within a game session |
| `playerstatus` | Per-user stats: total games, wins, losses, accuracy, XP |
| `totaltable` | All-time leaderboard, refreshed after every game |
| `weektable` | Weekly leaderboard (wins in the last 7 days) |

### Database Triggers

- **`trg_addxp_after_correct_answer`** — Automatically grants XP when a correct answer is recorded
- **`trg_limitquestionspercategory`** — Enforces a maximum of 50 questions per category
- **`trg_preventduplicateanswer`** — Prevents a user from submitting more than one answer per round

---

## ✅ Prerequisites

- Python **3.10+**
- PostgreSQL **17** (or compatible)
- The following Python packages:

```
psycopg2
bcrypt
tabulate
```

---

## 🚀 Installation

**1. Clone the repository**

```bash
git clone https://github.com/your-username/QuizOfQueen.git
cd QuizOfQueen
```

**2. Install Python dependencies**

```bash
pip install psycopg2-binary bcrypt tabulate
```

**3. Set up the PostgreSQL database**

```bash
# Create the database
psql -U postgres -c "CREATE DATABASE \"QuizOfQueen\";"

# Restore the schema and seed data
psql -U postgres -d QuizOfQueen -f DB_backup.sql
```

**4. Run the game**

```bash
python src/client/main.py
```

---

## ⚙️ Configuration

Database connection settings are in `src/DataBase/DataBase.py`:

```python
def get_connection():
    return psycopg2.connect(
        dbname="QuizOfQueen",
        user="postgres",
        password="admin",       # ← change this
        host="localhost",
        port="5432"
    )
```

Update `password` (and any other fields) to match your local PostgreSQL setup before running the game.

---

## 🎮 How to Play

1. **Start the game** — Run `python src/client/main.py`
2. **Sign in or register** — Create an account with a username, email, and password
3. **Start a game** — Choose "Start Game" from the main menu
4. **Pick an opponent** — Enter a username or type `random` to be matched automatically
5. **Play 5 rounds:**
   - Each round, **Player 1** selects a category and difficulty
   - Both players answer 3 questions each (60 seconds per question)
   - Correct answers earn points and XP
6. **Results** — The player with the most correct answers wins; the leaderboard updates automatically

---

## 👤 User Roles

Roles are assigned automatically based on the user ID (even = Admin, odd = Regular User):

| Feature | Regular User | Admin |
|---|:---:|:---:|
| Play games | ✅ | ✅ |
| Submit questions | ✅ (pending approval) | ✅ (auto-approved) |
| View player profiles | ✅ | ✅ |
| View leaderboards | ✅ | ✅ |
| Approve/reject questions | ❌ | ✅ |
| Activate/deactivate users | ❌ | ✅ |

---

## 🏆 XP & Scoring System

XP is awarded at the end of each round based on this formula:

```
XP = ((correct × 3 − wrong) / 3) × 100 × difficulty_multiplier
```

| Difficulty | Multiplier |
|---|:---:|
| Easy | ×1 |
| Medium | ×2 |
| Hard | ×3 |

**Time penalty:** Exceeding the 60-second limit on a single question ends the game immediately — the timed-out player loses.

The all-time leaderboard ranks players by total accumulated XP. The weekly leaderboard ranks by number of wins in the past 7 days.

---

## 🛡️ Admin Features

Admins access the same main menu as regular users, but two options are unlocked:

- **Approve New Questions** — Lists all pending questions in a table; enter a question ID to approve it, or `0` to exit
- **Change Player Activity Status** — Set any user's status to `active` or `inactive` (inactive users cannot play or submit questions)
