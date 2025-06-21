from src.DataBase.DataBase import get_connection
def get_last_question_id() -> int:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT MAX(questionid) FROM questions")
    result = cursor.fetchone()
    conn.close()
    return result[0] if result[0] is not None else 0
def add_question_to_db(username):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT userid , status FROM users WHERE username = %s", (username,))
    result = cursor.fetchone()
    if result is None:
        print("No such user exists.")
        return
    else:
        author_id_input = result[0]
        author_status = result[1]
    if author_status == 'inactive':
        print("You cannot add questions.")
        return

    while True:
        category_id_input = input("What is your category?:"
                                  "\n(1) History"
                                  "\n(2) Movie"
                                  "\n(3) Music"
                                  "\n(4) Sport"
                                  "\n(5) Foods"
                                  "\n(6) Geography\n").strip()
        if category_id_input in ['1','2','3','4','5','6']:
            category_id = int(category_id_input)
            break
        else:
            print("Invalid input. Please enter a number from 1 to 6.")

    while True:
        text = input("Question text: ").strip()
        if text:
            break
        else:
            print("Question text cannot be empty. Please re-enter.")

    while True:
        optionA = input("Option A: ").strip()
        if optionA:
            break
        else:
            print("Option A cannot be empty. Please re-enter.")

    while True:
        optionB = input("Option B: ").strip()
        if optionB:
            break
        else:
            print("Option B cannot be empty. Please re-enter.")

    while True:
        optionC = input("Option C: ").strip()
        if optionC:
            break
        else:
            print("Option C cannot be empty. Please re-enter.")

    while True:
        optionD = input("Option D: ").strip()
        if optionD:
            break
        else:
            print("Option D cannot be empty. Please re-enter.")

    # Loop for correct option input
    while True:
        correct_option = input("Correct option (A/B/C/D): ").strip().upper()
        if correct_option in ['A', 'B', 'C', 'D']:
            break
        else:
            print("Invalid input. Please enter A, B, C, or D.")

    while True:
        difficulty_level = input("Difficulty level (easy, medium, hard): ").strip().lower()

        if difficulty_level in ['easy', 'medium', 'hard']:
            break
        elif difficulty_level == 'e':
            difficulty_level = 'easy'
            break
        elif difficulty_level == 'm':
            difficulty_level = 'medium'
            break
        elif difficulty_level == 'h':
            difficulty_level = 'hard'
            break
        else:
            print("Invalid input. Please enter 'easy', 'medium', or 'hard'.")

    try:
        new_question_id = get_last_question_id() + 1
        author_id = int(author_id_input)
        if author_id % 2 == 0:
            status = 'approved'
        else:
            status = 'pending'

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
        cursor.close()
        print("The question was successfully added to the database.")
    except ValueError:
        print("Error: ID must be an integer.")
    finally:
        conn.close()