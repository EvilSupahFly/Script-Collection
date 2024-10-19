# Function to randomly rotate colours in PS1
rotate_colours() {
    local colours=(56 240 28 196 226 46)  # Define an array of colour codes
    local random_colour=${colours[RANDOM % ${#colours[@]}]}  # Select a random colour

    # Update PS1 with the randomly selected colour
    PS1="\e[1;38;5;${random_colour}m\u \e[38;5;240mon \e[1;38;5;28m\h \e[38;5;240mat \e[1;38;5;${random_colour}m\[$(date +'%a %-d %b %Y %H:%M:%S %Z')\]\e[0m\n\e[0;38;5;${random_colour}m[\w]\e[0m"

    # Bind the Enter key to the rotation function
    bind -x '"\C-m": rotate_colours'
}

rotate_colours  # Initialize the function
