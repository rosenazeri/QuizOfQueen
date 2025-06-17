from src.controllers.AddQuestion import add_question_to_db
from src.controllers.BlockUser import block_user
from src.controllers.PlayGame import play_game, update_totaltable
from src.controllers.PlayerStatusTable import player_status
from src.controllers.ShowTotalTable import leaderboard
from src.controllers.SignInSignUp import sign_in, sign_up


def main():
    print("به بازی Quiz of Queen خوش آمدید!")
    print("1. ورود (Sign In)")
    print("2. ثبت‌نام (Sign Up)\n")

    while True:
        choice = input("انتخاب کنید (1 یا 2): ").strip()

        if choice == "1":
            sign_in()
            break
        elif choice == "2":
            sign_up()
            break
        else:
            print("ورودی نامعتبر. لطفاً فقط عدد 1 یا 2 را وارد کنید.")

    while True:
        print("\n--- منوی اصلی ---")
        print("1. شروع بازی")
        print("2. مشاهده پروفایل اشخاص")
        print("3. جدول رتبه‌بندی")
        print("4. افزودن سوال")
        print("5. بلاک کردن کاربر")
        print("6. خروج")

        menu_choice = input("انتخاب شما: ").strip()

        if menu_choice == "1":
            play_game()
            update_totaltable()
        elif menu_choice == "2":
            player_status()
        elif menu_choice == "3":
            leaderboard()
        elif menu_choice == "4":
            add_question_to_db()
        elif menu_choice == "5":
            block_user()
        elif menu_choice == "6":
            print("خروج از برنامه. موفق باشید!")
            break
        else:
            print("گزینه نامعتبر. لطفاً عددی بین 1 تا 6 وارد کنید.")

if __name__ == "__main__":
    main()
