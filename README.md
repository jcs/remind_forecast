print a forecast of upcoming events from [remind(1)](http://www.roaringpenguin.com/products/remind),
or [icalBuddy](https://github.com/ali-rantakari/icalBuddy) on OS X.

with an example ~/.reminders file of:

	REM 6 august 2010 *1 until 8 august 2010	MSG something here
	REM 5 august 2010 at 8:45			MSG some timed event
	REM 1 september 2010				MSG some far out event

this utility will print (when run on august 5th)

	jcs@humble:~> ruby remind_forecast.rb
	some far out event in 3 weeks, 6 days (wed 1 sep)
	something here in 1 day (fri 6 aug to sun 8 aug)
	some timed event today at 08:45 (thu 5 aug)
