from tabulate import tabulate
from src.DataBase.DataBase import get_connection
def q_status(username):
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT userid FROM users WHERE username = %s", (username,))
        result = cursor.fetchone()

        if result is None:
            print("Such a user does not exist.")
            return
        else:
            userid = result[0]

        if userid % 2 == 0:
            cursor.execute(
                """SELECT Q.questionid, Q.text, Q.optiona, Q.optionb, Q.optionc, Q.optiond, Q.correctoption, Q.difficultylevel, C.name
                   FROM categories C JOIN questions Q ON C.categoryid = Q.categoryid
                   WHERE Q.status = 'pending'
                """
            )
            rows_data = cursor.fetchall()

            headers = ["ID", "Text", "A", "B", "C", "D", "Correct Answer", "Level", "Category"]
            print(tabulate(rows_data, headers=headers, tablefmt="grid"))

            finish = False
            while not finish:
                qid_input = input("Enter the question ID to approve, or 0 to exit: ")
                try:
                    qid = int(qid_input)
                except ValueError:
                    print("Please enter a number.")
                    continue

                if qid != 0:
                    cursor.execute(
                        """UPDATE questions
                           SET status = 'approved'
                           WHERE questionid = %s""", (qid,)
                    )
                    print("Question status successfully updated.")
                    conn.commit()
                else:
                    finish = True

        else: print("This option is not possible for users")
    except Exception as e:
        print("An error occurred during execution:", e)
    finally:
        if conn:
            conn.close()