#!/usr/bin/env python

import subprocess
import RPi.GPIO as GPIO
import time

# GPIO setup
FAN_PIN = 17  # Adjust pin number as needed
GPIO.setmode(GPIO.BCM)
GPIO.setup(FAN_PIN, GPIO.OUT)

# Function to read CPU temperature
def get_cpu_temperature():
    output = subprocess.check_output(['vcgencmd', 'measure_temp']).decode('utf-8')
    temperature_str = output.split('=')[1].split('\'')[0]
    temperature = float(temperature_str)
    return temperature

# Function to control fan based on CPU temperature
def control_fan():
    cpu_temp = get_cpu_temperature()
    if cpu_temp > 50:  # Adjust threshold temperature as needed
        GPIO.output(FAN_PIN, GPIO.HIGH)  # Turn fan on
    else:
        GPIO.output(FAN_PIN, GPIO.LOW)  # Turn fan off

# Main loop to continuously monitor CPU temperature and control fan
try:
    while True:
        control_fan()
        time.sleep(10)  # Adjust frequency of temperature checks as needed

except KeyboardInterrupt:
    GPIO.cleanup()
