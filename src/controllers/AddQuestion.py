from src.DataBase.DataBase import get_connection
def get_last_question_id() -> int:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT MAX(questionid) FROM questions")
    result = cursor.fetchone()
    conn.close()
    return result[0] if result[0] is not None else 0
def add_question_to_db():
    conn = get_connection()
    cursor = conn.cursor()
    username = str(input("نام کاربری خود را وارد کنید: "))
    cursor.execute("SELECT userid FROM users WHERE username = %s", (username,))
    result = cursor.fetchone()
    if result is None:
        print("چنین کاربری وجود ندارد.")
        exit()
    else:
        author_id_input = result[0]
    try:
        author_id = int(author_id_input)

        category_id_input = input("کتگوری شما کدام گزینه است؟:"
                                  "\n(1) History"
                                  "\n(2) Movie"
                                  "\n(3) Music"
                                  "\n(4) Sport"
                                  "\n(5) Foods"
                                  "\n(6) Geography\n").strip()

        text = input("متن سوال: ").strip()
        optionA = input("گزینه A: ").strip()
        optionB = input("گزینه B: ").strip()
        optionC = input("گزینه C: ").strip()
        optionD = input("گزینه D: ").strip()
        correct_option = input("گزینه صحیح (A/B/C/D): ").strip().upper()

        difficulty_level = input("سطح دشواری (easy , medium , hard): ").strip().lower()
        category_id = int(category_id_input)

        new_question_id = get_last_question_id() + 1
        status = None

        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute('''
                             INSERT INTO questions (
                                 questionid, text, optionA, optionB, optionC, optionD,
                                 correctoption, difficultylevel, categoryid, authorid, status
                             ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        ''', (
            new_question_id, text, optionA, optionB,
            optionC, optionD, correct_option,
            difficulty_level, category_id, author_id,
            status
        ))
        conn.commit()
        conn.close()
        print("✅ سؤال با موفقیت به پایگاه داده اضافه شد.")

    except ValueError:
        print("❌ خطا: شناسه باید عدد صحیح باشد.")