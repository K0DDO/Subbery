from pathlib import Path

from PIL import Image

SRC = Path(
    r'C:\Users\dima4ka\.cursor\projects\c-Users-dima4ka-Documents-Visual-Studio-2022-Subbery\assets\c__Users_dima4ka_AppData_Roaming_Cursor_User_workspaceStorage_55d300210508c324baabe91a2d52938c_images_image-6ac30c6f-cdcc-4417-befd-9c5b3da776ef.png'
)
OUT_DIR = Path('assets/icons')


def main() -> None:
    image = Image.open(SRC).convert('RGB')
    # Manual crops of only the "Subberry" word + leaf, no icon / slogan.
    dark = image.crop((340, 125, 930, 255))
    light = image.crop((340, 532, 930, 662))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    dark_path = OUT_DIR / 'subberry_wordmark_dark.png'
    light_path = OUT_DIR / 'subberry_wordmark_light.png'
    dark.save(dark_path)
    light.save(light_path)
    print(f'saved {dark_path} {dark.size}')
    print(f'saved {light_path} {light.size}')


if __name__ == '__main__':
    main()
