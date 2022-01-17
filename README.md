# Countdown

Created: December 22, 2021 9:38 PM
Tier: Beginner

Android - https://play.google.com/store/apps/details?id=com.chrisstayte.countdowns&hl=en&gl=US

iOS - https://apps.apple.com/us/app/countdowns-chris-stayte/id1603744166


The objective of Countdown Timer is to provide a continuously decrementing display of the he months, days, hours, minutes, and seconds to a user entered event.

### Constraints

- Use only builtin language functions for your calculations rather than relying on a library or package.
- Can’t use any code generators such as the counting down to site.

### **User Stories**

- [X]  User can see an event input box containing an event name field, an date field, an optional time, and a ‘Start’ button.
- [ ]  User can define the event by entering its name, the date it is scheduled to take place, and an optional time of the event. If the time is omitted it is assumed to be at Midnight on the event date in the local time zone.
- [X]  User can see a warning message if the event name is blank.
- [X]  User can see a warning message if the event date or time are incorrectly entered.
- [X]  User can see a warning message if the time until the event data and time that has been entered would overflow the precision of the countdown timer.
- [ ]  User can click on the ‘Start’ button to see the countdown timer start displaying the days, hours, minutes, and seconds until the event takes place.
- [X]  User can see the elements in the countdown timer automatically decrement. For example, when the remaining seconds count reaches 0 the remaining minutes count will decrement by 1 and the seconds will start to countdown from 59. This progression must take place from seconds all the way up to the remaining days position in countdown display.

### **Bonus features**

- [X]  User can save the event so that it persists across sessions
- [ ]  User can see an alert when the event is reached
- [X]  User can specify more than one event.
- [X]  User can see a countdown timers for each event that has been defined.


