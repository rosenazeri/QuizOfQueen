from datetime import datetime, time
from src.DataBase.DataBase import get_connection
def play_game():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT MAX(sessionid) FROM gamesessions")
    max_id = cursor.fetchone()[0]
    new_session_id = 1 if max_id is None else max_id + 1

    player1 = str(input("نام کاربری بازیکن اول وارد شود: "))
    cursor.execute("SELECT userid, status FROM users WHERE username = %s", (player1,))
    result1 = cursor.fetchone()
    if not result1:
        print("❌ بازیکن اول یافت نشد.")
        return
    elif result1[1] != 'active':
        print("❌ وضعیت بازیکن اول فعال نمی‌باشد.")
        return

    player2 = str(input("نام کاربری بازیکن دوم وارد شود: "))
    cursor.execute("SELECT userid, status FROM users WHERE username = %s", (player2,))
    result2 = cursor.fetchone()
    if not result2:
        print("❌ بازیکن دوم یافت نشد.")
        return
    elif result2[1] != 'active':
        print("❌ وضعیت بازیکن دوم فعال نمی‌باشد.")
        return

    cursor.execute("SELECT userid FROM users WHERE username = %s", (player1,))
    player1_id = cursor.fetchone()[0]
    cursor.execute("SELECT userid FROM users WHERE username = %s", (player2,))
    player2_id = cursor.fetchone()[0]
    start_time = datetime.now()
    cursor.execute("""
        INSERT INTO gamesessions (sessionid, player1id, player2id, starttime)
        VALUES (%s, %s, %s, %s)
    """, (new_session_id, player1_id, player2_id, start_time))
    conn.commit()

    score1 = 0
    score2 = 0
    loser = None
    xp1 = 0
    xp2 = 0

    for round_number in range(1, 6):
        scorenum1 = 0
        scorenum2 = 0
        print(f"\n📘 شروع راند {round_number}")

        cat = input("یک کتگوری انتخاب کن:"
                    "\n(1) History"
                    "\n(2) Movie"
                    "\n(3) Music"
                    "\n(4) Sport"
                    "\n(5) Foods"
                    "\n(6) Geography\n").strip()

        difficulty = input("سطح سختی ( E:easy / M:medium / H:hard ): ").strip().lower()

        if difficulty == 'e':
            difficulty = 'easy'
        elif difficulty == 'm':
            difficulty = 'medium'
        elif difficulty == 'h':
            difficulty = 'hard'
        else:
            print("ورودی نامعتبر است، سطح سختی به عنوان متوسط تنظیم شد.")
            difficulty = 'medium'
        cursor.execute("""
            SELECT questionid, text, correctoption, optiona, optionb, optionc, optiond 
            FROM questions 
            WHERE categoryid = %s AND difficultylevel = %s
            ORDER BY RANDOM() LIMIT 6
        """, (cat, difficulty))
        questions = cursor.fetchall()

        if len(questions) < 6:
            print("❌ سوالات کافی برای این دسته و سطح سختی وجود ندارد.")
            return

        round_start_time = datetime.now()

        print(f"\n👤 نوبت بازیکن {player1}")
        for i in range(3):
            q = questions[i]
            print(f"\nسوال: {q[1]}")
            print(f"A) {q[3]}\nB) {q[4]}\nC) {q[5]}\nD) {q[6]}")
            start = time.time()
            answer = input("گزینه (A/B/C/D): ").strip().upper()
            elapsed = time.time() - start

            if elapsed > 60:
                print("⏱ زمان شما تمام شد!")
                loser = player1_id
                break

            if answer.upper() == q[2].upper():
                print("✅ درست بود!")
                score1 += 1
                scorenum1 +=1
            else:
                print(f"❌ اشتباه بود. پاسخ صحیح: {q[2].upper()}")

        if loser:
            break

        print(f"\n👤 نوبت بازیکن {player2}")
        for i in range(3, 6):
            q = questions[i]
            print(f"\nسوال: {q[1]}")
            print(f"A) {q[3]}\nB) {q[4]}\nC) {q[5]}\nD) {q[6]}")
            start = time.time()
            answer = input("گزینه (A/B/C/D): ").strip()
            elapsed = time.time() - start

            if elapsed > 60:
                print("⏱ زمان شما تمام شد!")
                loser = player2_id
                break

            if answer.upper() == q[2].upper():
                print("✅ درست بود!")
                score2 += 1
                scorenum2+=1
            else:
                print(f"❌ اشتباه بود. پاسخ صحیح: {q[2].upper()}")

        if loser:
            break
        # XP و وضعیت بازیکنان
        if difficulty == 'hard':
            multiplier = 3
        elif difficulty == 'medium':
            multiplier = 2
        elif difficulty == 'easy':
            multiplier = 1
        else:
            multiplier = 1

        xp1 = xp1 + (((scorenum1 * 3) - (3 - scorenum1)) / 3) * 100 * multiplier
        xp2 = xp2 + (((scorenum2 * 3) - (3 - scorenum2)) / 3) * 100 * multiplier

        round_id = int(f"{new_session_id:02d}{round_number}")
        cursor.execute("""
            INSERT INTO rounds (roundid, sessionid, roundnumber, starttime, endtime)
            VALUES (%s, %s, %s, %s, %s)
        """, (round_id ,new_session_id, round_number, round_start_time, datetime.now()))
        conn.commit()

    if loser:
        winner_id = player2_id if loser == player1_id else player1_id
        print(f"\n❌ بازیکن {loser} بیش از 1 دقیقه تأخیر داشت. بازی را باخت.")
    else:
        if score1 > score2:
            winner_id = player1_id
        elif score2 > score1:
            winner_id = player2_id
        else:
            winner_id = None

    end_time = datetime.now()

    cursor.execute("""
        UPDATE gamesessions
        SET endtime = %s, status = %s, winnerid = %s
        WHERE sessionid = %s
    """, (end_time, 'completed', winner_id, new_session_id))
    conn.commit()

    print("\n🏁 بازی پایان یافت.")
    print(f"امتیاز بازیکن {player1}: {score1}")
    print(f"امتیاز بازیکن {player2}: {score2}")
    if winner_id == player1_id:
        print(f"🏆 برنده: بازیکن {player1}")
    elif winner_id == player2_id:
        print(f"🏆 برنده: بازیکن {player2}")
    else:
        print("🤝 بازی مساوی شد.")

    if winner_id == player1_id:
        cursor.execute("UPDATE playerstatus SET gameswon = gameswon + 1, totalgames = totalgames + 1, accuracy = %s, xp = xp + %s WHERE userid = %s", (score1, xp1, player1_id))
        cursor.execute("UPDATE playerstatus SET gameslost = gameslost + 1, totalgames = totalgames + 1, accuracy = %s, xp = xp + %s WHERE userid = %s", (score2, xp2, player2_id))
    elif winner_id == player2_id:
        cursor.execute("UPDATE playerstatus SET gameswon = gameswon + 1, totalgames = totalgames + 1, accuracy = %s, xp = xp + %s WHERE userid = %s", (score2, xp2, player2_id))
        cursor.execute("UPDATE playerstatus SET gameslost = gameslost + 1, totalgames = totalgames + 1, accuracy = %s, xp = xp + %s WHERE userid = %s", (score1, xp1, player1_id))
    else:
        cursor.execute("UPDATE playerstatus SET totalgames = totalgames + 1, accuracy = %s , xp = xp + %s WHERE userid = %s", (score1, xp1, player1_id,))
        cursor.execute("UPDATE playerstatus SET totalgames = totalgames + 1, accuracy = %s , xp = xp + %s WHERE userid = %s", (score2, xp2, player2_id,))
        print("امتیازات مساوی بودند، هیچ برد و باختی ثبت نشد.")

    conn.commit()
def update_totaltable():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("TRUNCATE TABLE totaltable")

    cursor.execute("""
        SELECT 
            u.userid,
            u.username,
            ps.xp
        FROM 
            users u
        JOIN 
            playerstatus ps ON u.userid = ps.userid
        ORDER BY ps.xp DESC
    """)
    rows = cursor.fetchall()

    rank = 1
    last_xp = None
    count = 0
    for row in rows:
        userid, username, xp = row
        count += 1
        if last_xp != xp:
            rank = count
        last_xp = xp
        cursor.execute("""
            INSERT INTO totaltable (userid, username, xp, rank)
            VALUES (%s, %s, %s, %s)
        """, (userid, username, xp, rank))

    conn.commit()
    cursor.close()
    conn.close()