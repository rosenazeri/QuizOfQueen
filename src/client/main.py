from src.controllers.AddQuestion import add_question_to_db
from src.controllers.BlockUser import block_user
from src.controllers.CategoryTable import cattable
from src.controllers.PlayGame import play_game
from src.controllers.PlayerStatusTable import player_status
from src.controllers.ShowQuestionsToApproved import q_status
from src.controllers.ShowTotalTable import leaderboard
from src.controllers.SignInSignUp import sign_in, sign_up
from src.controllers.weekstatus import weekboard

def main():
    print("Welcome to the Quiz of Queen game!")
    print("1. Sign In")
    print("2. Sign Up\n")

    while True:
        choice = input("Please select (1 or 2): ").strip()

        if choice == "1":
            username = sign_in()
            break
        elif choice == "2":
            username = sign_up()
            break
        else:
            print("Invalid input. Please enter only 1 or 2.")

    while True:
        print("\n--- Main Menu ---")
        print("1. Start Game")
        print("2. View Player Profile")
        print("3. Ranking Tables")
        print("4. Change Player Activity Status")
        print("5. Add Question")
        print("6. Approve New Questions")
        print("7. Exit")

        menu_choice = input("Your choice: ").strip()

        if menu_choice == "1":
            play_game(username)
        elif menu_choice == "2":
            player_status()
        elif menu_choice == "3":
            print("Overall Leaderboard")
            leaderboard()

            print("Weekly Leaderboard")
            weekboard()

            print("Most Played Category")
            cattable()
        elif menu_choice == "4":
            block_user(username)
        elif menu_choice == "5":
            add_question_to_db(username)
        elif menu_choice == "6":
            q_status(username)
        elif menu_choice == "7":
            print("Exiting the program. Good luck!")
            break
        else:
            print("Please enter a number between 1 and 7.")

if __name__ == "__main__":
    main()