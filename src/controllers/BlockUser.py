from src.DataBase.DataBase import get_connection

def block_user(username):
    conn = get_connection()
    cursor = conn.cursor()

    while True:
        cursor.execute("SELECT userid FROM users WHERE username = %s", (username,))
        result = cursor.fetchone()
        if result is not None:
            userid = result[0]
            break
        else:
            print("Such a user does not exist. Please try again.")
            username = input("Enter your username again: ").strip().lower()

    if userid % 2 == 0:
        try:
            while True:
                target_username = input("Please enter the target user's username: ").strip().lower()
                cursor.execute("SELECT userid FROM users WHERE username = %s", (target_username,))
                result = cursor.fetchone()
                if result is not None:
                    target_userid = result[0]
                    break
                else:
                    print("Such a user does not exist. Please try again.")

            while True:
                new_status = input("Enter the new status ('active' or 'inactive'): ").strip().lower()
                if new_status in ("active", "inactive"):
                    break
                else:
                    print("Invalid status. Please enter 'active' or 'inactive'.")

            cursor.execute("UPDATE users SET status = %s WHERE userid = %s", (new_status, target_userid))
            conn.commit()
            print("Operation completed.")

        except ValueError:
            print("ID must be a number.")

    else:
        print("This feature is not available for you.")

    conn.close()
