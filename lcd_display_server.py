import board
import busio
import adafruit_character_lcd.character_lcd_rgb_i2c as character_lcd
from oscpy.server import OSCThreadServer
from oscpy.client import OSCClient
from time import sleep

lcd_columns=16
lcd_rows = 2
i2c = busio.I2C(board.SCL, board.SDA)
lcd = character_lcd.Character_LCD_RGB_I2C(i2c, lcd_columns, lcd_rows)
lcd.color=[100,0,0]
lcd.clear()

status = "Stand by..."
name = ""

def messageCallback(*values):
	global status
	status = values[0].decode("utf-8")
	printLCDMessage()

def nameCallback(*values):
	global name
	name = values[0].decode("utf-8")
	printLCDMessage()

def printLCDMessage():
	global status, name
	lcd.message=status+"\n"+name
	sleep (3)
	lcd.clear()
	lcd.message=status

osc = OSCThreadServer()
sock = osc.listen(address="127.0.0.1",port=8000,default=True)
osc.bind(b'/message', messageCallback)
osc.bind(b'/name', nameCallback)

button = OSCClient("127.0.0.1", 8001)

while(True):
	if lcd.right_button:
		button.send_message(b"/button",[0])
		sleep(0.5)
	sleep(0.25)

osc.stop()

