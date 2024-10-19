# Randomly Rotate colours in Bash Prompt

For the best experience, add this script to either `$HOME/.bashrc` or to `/etc/bash.bashrc`.

## Have you ever wanted to add a splash of colour to your terminal prompt?
Well, you're in luck! This Bash function randomly rotates colours in your command prompt (PS1), making your terminal experience a bit more vibrant and fun!

## Key Concepts

PS1: This is the primary prompt string in Bash. It defines how your command prompt looks.
ANSI colour Codes: These are codes used to set text colours in the terminal. In this code, we use a specific range of colour codes.
Randomization: The function utilizes Bash's built-in $RANDOM variable to select a colour randomly from an array.

## Code Structure
The function rotate_colours is structured to:

 - Define an array of colour codes
 - Randomly select one of those colours
 - Update the PS1 variable to reflect the new colour
 - Bind the Enter key to trigger the colour rotation

## Break down:

### Defining colours:
```
local colours=(56 240 28 196 226 46)
```
Here, we define an array of colour codes. Each number corresponds to a specific colour in the terminal.

### Selecting a Random colour:
```
local random_colour=${colours[RANDOM % ${#colours[@]}]}
```
This line uses the $RANDOM variable to select a random index from the colours array. The modulus operator ensures that the index stays within the bounds of the array.

### Updating the PS1 Variable:
```
PS1="\e[1;38;5;${random_colour}m\u \e[38;5;240mon \e[1;38;5;28m\h \e[38;5;240mat \e[1;38;5;${random_colour}m\[$(date +'%a %-d %b %Y %H:%M:%S %Z')\]\e[0m\n\e[0;38;5;${random_colour}m[\w]\e[0m"
```
This line constructs the new prompt string. It includes:
```

 - \u: Username
 - \h: Hostname
 - Current date and time
 - Current working directory (\w)
 - Colours applied using ANSI escape sequences
```
### Binding the Function to the Enter Key:
```
bind -x '"\C-m": rotate_colours'
```
This binds the Enter key (Control + M) to the rotate_colours function, allowing the prompt to change colours every time you press Enter.

### Initializing the Function:
```
rotate_colours
```
Finally, we call the function to set everything in motion and now your prompt will change colours
