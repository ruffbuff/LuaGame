from PIL import Image

image = Image.open("left.png")
flipped_image = image.transpose(Image.FLIP_LEFT_RIGHT)
flipped_image.save("right.png")