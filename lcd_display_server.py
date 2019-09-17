import board
import busio
import adafruit_character_lcd.character_lcd_rgb_i2c as character_lcd
from oscpy.server import OSCThreadServer
from time import sleep

lcd_columns=16
lcd_rows = 2
i2c = busio.I2C(board.SCL, board.SDA)
lcd = character_lcd.Character_LCD_RGB_I2C(i2c, lcd_columns, lcd_rows)
lcd.color=[100,0,0]
lcd.clear()

connected = "Disconnected"
name = ""

def connectionCallback(*values):
	connected = values[0]
	printLCDMessage()

def nameCallback(*values):
	name = values[0]
	printLCDMessage()

def printLCDMessage():
	lcd.message=connected+"\n"+name
	sleep (3)
	lcd.clear()
	lcd.message=connected

osc = OSCThreadServer()
sock = osc.listen(address="127.0.0.1",port=8000,default=True)
osc.bind(b'/connected', connectionCallback)
osc.bind(b'/name', nameCallback)

while(True):
	sleep(1000)

osc.stop()

