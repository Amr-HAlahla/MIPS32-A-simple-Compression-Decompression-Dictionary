.data
output_file: .space 100
output_file_prompt: .asciiz "please enter the path of the output file, .txt extended:\n"
uncompressed_path: .space 100
uncompressed_file_prompt: .asciiz "please enter the path of the uncompressed file, .txt extended:\n"
file_name: .space 100
dict_file_prompt: .asciiz "Please enter dictionary file name, .txt extended:\n"
PROMPT: .asciiz "Enter c to compress, d to decompress, or q to quit: "
answer: .space 10
codes_array: .space 4096
compressed_path: .asciiz "compressed.txt"
dict_content: .space 4096 # buffer of uncompressed file
file_content: .space 4096 # buffer of dictionary file
compressed_content: .space 2096
specials: .asciiz ";\n:\n#\n$\n%\n&\n*\n@\n!\n.\n,\n?"
code: .byte 0
null_char:   .byte 0   # Null character
space: .asciiz " "
error_message: .asciiz "Error opening file.\n"
error_message2: .asciiz "Error opening compressed file.\n"
newline: .asciiz "\n"
myword: .space 30
extracted_word: .space 30
corresponding_word: .space 30
array: .space 4096
loop_string: .asciiz "\nEntering loop\n"
bye_message: .asciiz "\nBye!\n"
s_char: .asciiz "\nspecial char "
not_found: .asciiz "\nword not found in dictionary\n"
my_char: .space 1
buffer: .space 4
ratio: .float 0.0
result_message: .asciiz "Compression Ration is : "
.text
.globl main

main:
  j load_dictionary
  close_dict:
  	li $v0, 16
  	move $a0, $s0
  	syscall
  
	menu:  
  	li $v0, 4
  	la $a0, PROMPT
 	syscall
	
	li $v0, 8
	la $a0, answer
	li $a1, 10
	syscall
	
	la $t0, answer 
	find_end_of_answer:
    	lb $t1, 0($t0)   # Load a byte from the string
    	beq $t1,'\n', answer_done   # Branch if null terminator is found
    	beq $t1,' ',  answer_done  # Branch if null terminator is found
    	beqz $t1, answer_done  # Branch if null terminator is found
    	addiu $t0, $t0, 1    # Move to the next character
    	j find_end_of_answer
 	
 	answer_done:
 	sb $zero, 0($t0)  # Replace null terminator with zero
	# Check user's choice
    	lb $t0, answer
    	beq $t0, 99, read_uncopmressed_file   # If choice is 'c', go to compress function
    	beq $t0, 100, decompress # If choice is 'd', go to decompress function
    	beq $t0, 113, compression_ratio      # If choice is 'q', exit program
    	j menu 
  
# processing uncompressed file, read and store.  
  j read_uncopmressed_file
  
  close_file:
  	li $v0, 16
  	move $a0, $s0
  	syscall # close uncompressed file.
  	j compress
  
read_uncopmressed_file:

    # Prompt the user to enter the file name
    li $v0, 4
    la $a0, uncompressed_file_prompt
    syscall

    # Read the file name from the user
    li $v0, 8
    la $a0, uncompressed_path
    li $a1, 100
    syscall

    # Find the end of the string
    move $t0, $a0    # $t0 will hold the file name pointer
    find_end_of_name:
    	lb $t1, 0($t0)   # Load a byte from the string
    	beq $t1,'\n', open_uncopmressed_file   # Branch if null terminator is found
    	beq $t1,' ', open_uncopmressed_file   # Branch if null terminator is found
    	beqz $t1, open_uncopmressed_file   # Branch if null terminator is found
    	addiu $t0, $t0, 1    # Move to the next character
    	j find_end_of_name
 
    open_uncopmressed_file:
    	# Terminate the string
    	sb $zero, 0($t0)  # Replace null terminator with zero

    	# Open the file
    	li $v0, 13       # Open file syscall code
    	la $a0, uncompressed_path
    	la $a1, 0 # open file for append
    	syscall

    	# Check if the file was opened successfully
    	bltz $v0, error   # error
	
   move $s0, $v0  # save file descriptor in $s0

  # Read content of file
  li $v0, 14
  move $a0, $s0
  la $a1, file_content
  li $a2, 4096
  syscall

  # Split content by space and print each word on a separate line
  la $t0, file_content
  li $t1, ' '
  la $s1, myword
  li $s2, 0 # save the word lenght.
split_loop:
	li $t1, ' '
  	lb $t2, ($t0)
  	beqz $t2, enter_array  # end of file
  	 #if special char occur occur, then its word, go check if its unique or not
 	beq $t2, $t1, enter_array
 	beq $t2, ' ', enter_array
        beq $t2, '\t', enter_array
        beq $t2, ',', enter_array
        beq $t2, '.', enter_array
        beq $t2, ';', enter_array
        beq $t2, ':', enter_array
        beq $t2, '&', enter_array
        beq $t2, '*', enter_array
  	# append the current character to the current word
  	sb $t2, ($s1)       # store the current character in the current word buffer
  	addi $s1, $s1, 1    # increment the current word buffer pointer
  	addi $s2, $s2, 1    # increment the word's length.
increment:  
  	addi $t0, $t0, 1    # increment the file content pointer
  	j split_loop

				
enter_array:
	sb $zero, ($s1) # terminate each word extracted (key-word) from the file
	la $s1, myword # load the key word address
	la $s3, array # point to the start of the array
	la $s4, extracted_word # point to the word to be extracted from array.
	li $t1, '\n'
	extract_word:
	lb $t3, ($s3) # load char from array.
	beqz $t3, compare_two_words # this is last word in the array.
	beq $t3, '\n', compare_two_words # exact word from array.
	sb $t3, ($s4) # append the char to the word.
	addi $s4,$s4,1 # increment the word buffer pointer.
	increment2:
	addi $s3, $s3, 1 # increment array pointer.
	j extract_word
	  	  	
	
compare_two_words:
    sb $zero, ($s4) # terminate the extracted word from the array.
    la $t4, myword # load the address of the first word.
    la $t5, extracted_word # load the address of the second word to be compared.
    # Loop through each character in the strings
    loop:
    	lb $t7, ($t4)      # Load current character of str1
    	lb $t8, ($t5)      # Load current character of str2
    	beqz $t7, exit     # If str1 is whitespace, exit
    	beqz $t8, exit     # If str2 is whitespace, exit
    	bne $t7, $t8, not_equal   # If characters are not equal, jump to not_equal
    	addi $t4, $t4, 1   # Increment str1 pointer
    	addi $t5, $t5, 1   # Increment str2 pointer
    	j loop # Continue looping
  
    exit:
    	beq $t7, $t8, equal    # If both strings are null-terminated, they are equal
    
    not_equal:
    	beqz $t3, add_to_array
    	j reset2 # reset registers and read new word from array
    	  		
    equal:
    	j reset1
    	
   reset1:
   	beqz $t2, close_file # if it was the last word in the file.
	# reset the current word buffer
  	la $s1, myword
  	# continue the loop
  	addi $s0, $s0, 1    # skip the space character
  	li $s2, 0 # reset the word length
  	# Loop until the end of the file is reached
  	bnez $t2, increment
  	
   reset2:
  	la $s4, extracted_word
  	j increment2
    	
  
add_to_array:
	# add the word to the dictionary file.
  add_to_dict_file:
	# Open the file for append
    	li $v0, 13           # System call code for opening a file
    	la $a0, file_name     # Load the address of the filename
    	li $a1, 9            # File access mode: 1 for write
    	li $a2, 0            # File permission: 0 for default
    	syscall	
    	
	# Get the file descriptor
    	move $s6, $v0
	
	# append newline to the file
	li $v0, 15           # System call code for writing to a file
	move $a0, $s6        # File descriptor
	la $a1, newline       # Load the address of the string
	li $a2, 1            # Length of the string
	syscall

	# Write the string to the file
    	li $v0, 15           # System call code for writing to a file
    	move $a0, $s6        # File descriptor
    	la $a1, myword         # Load the address of the string
    	move $a2, $s2       # Length of the string
    	syscall   
 	
    	# Close the file
    	li $v0, 16           # System call code for closing a file
    	move $a0, $s6        # File descriptor
    	syscall
	
	# store the word in the array
  	la $t4, myword    # load the address of the first word
  	lb $t6, ($t4)    # load char by char from the word to be added into the array
  	beqz $t6, terminate_array  # check if the current character is null-terminating (end of word)

  add_loop:
  	sb $t6, ($s5)    # add the current character to the array
  	addi $t4, $t4, 1  # increment the word pointer
  	lb $t6, ($t4)    # load the next character from the word
  	addi $s5, $s5, 1  # increment the array pointer
  	bnez $t6, add_loop  # continue the loop until the end of the word is reached

  terminate_array:
  	li $t1, '\n'
  	sb $t1, ($s5)    # add the newline character to the array after the added word.
  	addi $s5, $s5, 1  # increment the array pointer
  	sb $zero, ($s5)  # null-terminate the array
  	j reset1
	
  
load_dictionary:
    # Prompt the user to enter the file name
    li $v0, 4
    la $a0, dict_file_prompt
    syscall

    # Read the file name from the user
    li $v0, 8
    la $a0, file_name
    li $a1, 100
    syscall

    # Find the end of the string
    move $t0, $a0    # $t0 will hold the file name pointer
    find_end_of_dict:
    	lb $t1, 0($t0)   # Load a byte from the string
    	beq $t1,'\n', open_dict_file   # Branch if null terminator is found
    	beq $t1,' ', open_dict_file   # Branch if null terminator is found
    	beqz $t1, open_dict_file   # Branch if null terminator is found
    	addiu $t0, $t0, 1    # Move to the next character
    	j find_end_of_dict
 
    open_dict_file:
    	# Terminate the string
    	sb $zero, 0($t0)  # Replace null terminator with zero

    	# Open the file
    	li $v0, 13       # Open file syscall code
    	la $a0, file_name
    	la $a1, 0 # open file for append
    	syscall

    	# Check if the file was opened successfully
    	bltz $v0, error   # error
	move $s0, $v0
  	# Read content of file
 	li $v0, 14
  	move $a0, $s0
  	la $a1, dict_content
  	li $a2, 4096
  	syscall
	# load the dictionary into an array.
  	la $t0, dict_content
  	la $s5, array # address of the array.
  	#li $t1, ' ' # add whitespace char at the begining of the array.
  	#sb $t1, ($s5)
  	#addi $s5, $s5, 1
  
  read_dictionary:
  	lb $t1, ($t0)
  	beqz $t1, end_of_dict  # end of dictionary file, add the null terminator at the end of array.
  	sb $t1, ($s5)    # store the current character in the array
  	addi $s5, $s5, 1    # increment the array pointer
  	addi $t0, $t0, 1    # increment the file content pointer
  	j read_dictionary

  end_of_dict:
  	li $t9, '\n'
  	sb $t9,($s5) # add newline char after last word added to the array.
  	addi $s5, $s5, 1
	sb $zero, ($s5)
	j close_dict
	
print_array:
	la $a0, loop_string
	li $v0, 4
	syscall 
	
	sb $zero, ($s5)
	la $t1, array # load address of the array.		
  loop_through_array:
	lb $t0, ($t1) # load char from array.
	beqz $t0, full_exit # end of array
	#beqz $t0, read_compressed_file # end of array
	li $v0, 11 # print char
	move $a0, $t0
	syscall
	addi $t1, $t1, 1 # increment array pointer.
	j loop_through_array		

  end_of_print:
  	# Print error message
  	li $v0, 4
  	la $a0, bye_message
  	syscall
  	# Exit program
  	li $v0, 10
  	syscall


add_special_chars:
	# Open the file for append
    	li $v0, 13           # System call code for opening a file
    	la $a0, file_name     # Load the address of the filename
    	li $a1, 9            # File access mode: 9 for append
    	li $a2, 0            # File permission: 0 for default
    	syscall	
    	
	# Get the file descriptor
    	move $s6, $v0
	
	# add special chars to the file
	li $v0, 15           # System call code for writing to a file
	move $a0, $s6        # File descriptor
	la $a1, specials       # address of the string
	li $a2, 21            # Length of the string (1 byte)
	syscall
    	j print_array
	

compress:
    	# load the address of the array at where the codes will be stored.
    	la $t6, codes_array
    	
    	# Open the file
    	li $v0, 13       # Open file syscall code
    	la $a0, uncompressed_path
    	la $a1, 0 # open file for append
    	syscall
    	
	move $s0, $v0
  # Read content of file
  	li $v0, 14
  	move $a0, $s0
  	la $a1, file_content
  	li $a2, 4096
  	syscall
  
# Split content by special cahracters and extract words.
  	la $t0, file_content
  	la $s1, myword
  	li $s2, 0 # save the word lenght.
  	
extract_loop: # outer loop
  	lb $t1, ($t0)
  	beqz $t1, special_char  # end of file
  	#if special char occur occur, then its word, go check if its unique or not
 	beq $t1, ' ', special_char
        beq $t1,'\t', special_char
        beq $t1, ',', special_char
        beq $t1, '.', special_char
        beq $t1, ';', special_char
        beq $t1, ':', special_char
        beq $t1, '&', special_char
        beq $t1, '*', special_char	
  	# append the current character to the current word
  	sb $t1, ($s1)       # store the current character in the current word buffer
  	addi $s1, $s1, 1    # increment the current word buffer pointer
  	addi $s2, $s2, 1    # increment the word's length.
plusplus:  
  	addi $t0, $t0, 1    # increment the file content pointer
  	j extract_loop	
	
special_char: 
	lb $t9, code
	li $t9, 1 # initialize the code value with 0
	sb $t9, code 
	sb $zero, ($s1) # terminate each word extracted (key-word) from the file
	la $s1, myword # load the key word address
	la $s3, array # point to the start of the array
	la $s4, extracted_word # point to the word to be extracted from array.
	inner_loop:
	lb $t2, ($s3) # load char from array.
	beqz $t2, find_code # this is last word in the array.
	beq $t2, '\n', find_code # exact word from array.
	sb $t2, ($s4) # append the char to the word.
	addi $s4,$s4,1 # increment the word buffer pointer.
	plusplus2:
	addi $s3, $s3, 1 # increment array pointer.
	j inner_loop

find_code:
    	sb $zero, ($s4) # terminate the extracted word from the array.
    	la $t4, myword # load the address of the first word.
    	la $t5, extracted_word # load the address of the second word to be compared.
    	# Loop through each character in the strings
    compare_loop:
    	lb $t7, ($t4)      # Load current character of str1
    	lb $t8, ($t5)      # Load current character of str2
    	beqz $t7, done     # If str1 is whitespace, exit
    	beqz $t8, done     # If str2 is whitespace, exit
    	bne $t7, $t8, different   # If characters are not equal, jump to not_equal
    	addi $t4, $t4, 1   # Increment str1 pointer
    	addi $t5, $t5, 1   # Increment str2 pointer
    	j compare_loop # Continue looping
  		
    done:
    	beq $t7, $t8, same    # If both strings are null-terminated, they are equal
    
    different:
    	j return2 # reset registers and read new word from array
    	  		
    same: # word found at the array -> append its code into the compressed file
    	# print the word with its code to ensure.
   
	# Open the file for append (compressed_file)
    	li $v0, 13           # System call code for opening a file
    	la $a0, compressed_path     # Load the address of the compressed file
    	li $a1, 9            # File access mode: 9 for append
    	li $a2, 0            # File permission: 0 for default
    	syscall	
    	
	# Get the file descriptor
    	move $s7, $v0	
    	bltz $s7, error2
	
    	li $v0, 4
    	la $a0, myword
    	syscall
    	li $v0, 4
    	la $a0, space
    	syscall
    	li $v0, 4
    	la $a0, extracted_word
    	syscall    	
    	li $v0, 4
    	la $a0, space
    	syscall
    	
    	# add the code into codes_array
	lb $s6, code
	sb $s6, ($t6) # store the code
	addiu $t6,$t6,1 # increment array pointer.
    	
    	# Convert the code value to a decimal string
    	li $v0, 34              # System call number for integer to string conversion
    	lb $a0, code         # Load the counter value into $a0
    	la $a1, buffer          # Load the buffer address into $a1
    	li $a2, 4              # Maximum number of digits in the string
    	syscall

 	li $v0, 4
 	la $a0, buffer
 	syscall
	
	li $v0, 4
 	la $a0, newline
 	syscall
	
    	# write new line after each code
	li $v0, 15           # System call code for writing to a file
	move $a0, $s7        # File descriptor
	la $a1, newline       # code value
	li $a2, 1           # Length of the code (1 byte)
	syscall	  
	
	# close the file
	li $v0, 16
	move $a0, $s7
	syscall
	
	# now find and add the code of the special character.
	bnez $t1, find_special_code
	sb $zero, ($t6)
	#j close_file	  		  	  	  	
    	j closing 	

	
    return1:
   	beqz $t1, closing # if its last word in the file.
	# reset the current word buffer
  	la $s1, myword
  	# continue the loop
  	addi $s0, $s0, 1    # skip the space character
  	li $s2, 0 # reset the word length
  	# Loop until the end of the file is reached
  	bnez $t1, plusplus
  	
    return2:
  	la $s4, extracted_word
  	# increment teh code value
	lb $t9, code
	addi $t9, $t9, 1 
	sb $t9, code 	
  	j plusplus2 # continue search in the array.
  	
  	
    
    
find_special_code:
    beq $t1, ' ', label_0
    beq $t1, ';', label_1
    beq $t1, ':', label_2
    beq $t1, '#', label_3
    beq $t1, '$', label_4
    beq $t1, '%', label_5
    beq $t1, '&', label_6
    beq $t1, '*', label_7
    beq $t1, '@', label_8
    beq $t1, '!', label_9
    beq $t1, '.', label_10
    beq $t1, ',', label_11
    
    # Default case if none of the conditions matched
    li $t9, -1
    j end
    
label_0:
    lb $t9, code
    li $t9, 0
    sb $t9, code
    j end
    
label_1:
    lb $t9, code
    li $t9, 1
    sb $t9, code
    j end
    
label_2:
    lb $t9, code
    li $t9, 2
    sb $t9, code
    j end
    
label_3:
    li $t9, 3
    j end
    
label_4:
    lb $t9, code
    li $t9, 4
    sb $t9, code
    j end
    
label_5:
    lb $t9, code
    li $t9, 5
    sb $t9, code
    j exit
    
label_6:
    lb $t9, code
    li $t9, 6
    sb $t9, code
    j end
    
label_7:
    lb $t9, code
    li $t9, 7
    sb $t9, code
    j exit
    
label_8:
    lb $t9, code
    li $t9, 8
    sb $t9, code
    j end
    
label_9:
    lb $t9, code
    li $t9, 9
    sb $t9, code
    j exit
    
label_10:
    lb $t9, code
    li $t9, 10
    sb $t9, code
    j end
    
label_11:
    lb $t9, code
    li $t9, 11
    sb $t9, code
    j end
    
end:
	# Open the file for append (compressed_file)
    	li $v0, 13           # System call code for opening a file
    	la $a0, compressed_path     # Load the address of the compressed file
    	li $a1, 9            # File access mode: 9 for append
    	li $a2, 0            # File permission: 0 for default
    	syscall	
    	
	# Get the file descriptor
    	move $s7, $v0	
    	bltz $s7, error2
    	
    	li $v0, 4
    	la $a0, s_char
    	syscall
    	
    	li $v0, 4
    	lb $t1, ($t0) # load the special character value
    	sb $t1, my_char
    	la $a0, my_char # print the special char found.
    	syscall
    	
    	li $v0, 4
    	la $a0, space
    	syscall 
    	
    	# Convert the code value to a decimal string
    	li $v0, 34              # System call number for integer to string conversion
    	lb $a0, code         # Load the counter value into $a0
    	la $a1, buffer          # Load the buffer address into $a1
    	li $a2, 4              # Maximum number of digits in the string
    	syscall

    	# Print the code value
    	li $v0, 4               # System call number for print string
    	la $a0, buffer          # Load the buffer address into $a0
    	syscall
    
    	li $v0, 4
    	la $a0, newline
    	syscall
    	
        # append the code to the file
	#li $v0, 15           # System call code for writing to a file
	#move $a0, $s7        # File descriptor
	#la $a1, buffer       # code value
	#li $a2, 4             # Number of bytes to write
	#syscall

    	# write new line after each code
	#li $v0, 15           # System call code for writing to a file
	#move $a0, $s7        # File descriptor
	#la $a1, newline       # code value
	#li $a2, 1           # Length of the code (1 byte)
	#syscall	 
	# close the file
	li $v0, 16
	move $a0, $s7
	syscall
	#beqz $t1, close_file
	
	# add the code into codes_array
	lb $s6, code
	beqz $s6, return1 # skip storing the code in the array if it equals zero
	sb $s6, ($t6) # store the code
	addiu $t6,$t6,1
	
	j return1
	
print_codes_array:
	# print welcoming message
	li $v0, 4
	la $a0, loop_string
	syscall
	# new line
	li $v0, 4
	la $a0, newline
	syscall 
	
	la $t6, codes_array
	codes_loop:
		lb $s6, ($t6)
		beqz $s6, decompress
		# Convert the code value to a decimal string
    		li $v0, 34              # System call number for integer to string conversion
    		lb $a0, ($t6)         # Load the counter value into $a0
    		la $a1, buffer          # Load the buffer address into $a1
    		li $a2, 4              # Maximum number of digits in the string
    		syscall 
    		
    		li $v0, 4
    		la $a0, buffer
    		syscall
    		
		li $v0, 4
		la $a0, newline
		syscall
		addiu $t6,$t6,1
		j codes_loop

		
closing:
    # close uncopmressed file
    li $v0, 16
    move $a0, $s0
    syscall
    j menu  					
decompress:
    
    # Prompt the user to enter the file name
    li $v0, 4
    la $a0, output_file_prompt
    syscall

    # Read the file name from the user
    li $v0, 8
    la $a0, output_file
    li $a1, 100
    syscall

    # Find the end of the string
    move $t0, $a0    # $t0 will hold the file name pointer
    find_end:
    	lb $t1, 0($t0)   # Load a byte from the string
    	beq $t1,'\n', open_file   # Branch if null terminator is found
    	beq $t1,' ', open_file   # Branch if null terminator is found
    	beqz $t1, open_file   # Branch if null terminator is found
    	addiu $t0, $t0, 1    # Move to the next character
    	j find_end
 
    open_file:
    	# Terminate the string
    	sb $zero, 0($t0)  # Replace null terminator with zero

    	# Open the file
    	li $v0, 13       # Open file syscall code
    	la $a0, output_file
    	la $a1, 1 # open file for write
    	syscall

    	# Check if the file was opened successfully
    	bgez $v0, file_opened   # Branch if file handle is non-negative
	
    	j error2 # error opening file.
    	
    	file_opened:
    	move $s0, $v0 # save file descriptor
    	# now get the codes from the array and decode it to the suitable corresponding word.	
    	la $s1, codes_array # array of codes address
    	first_loop:
    		lb $t0, ($s1) # load the value of the code.
    		beqz $t0, menu # end of decoding process.
    		j find_corresponding_word
    		
    		next_code:
    		addiu $s1,$s1,1 # increment array pointer to the next code
    		j first_loop
	
	find_corresponding_word:
		li $s6, 0 # initialize word lenght
		la $s4, corresponding_word 
		li $s3, 1 # initialize the counter that reads number of lines.
		# now load the array of the dictionary words, and find the corresponding one.
		la $s2, array # load the dictionary array address.
		counter_loop:
		lb $t1, ($s2)
		beqz $t1, next_code # dictionary array is done, no corresponding word found.
		beq $t1, '\n', check_counter
		sb $t1, ($s4) # store the character in the word.
		addiu $s4, $s4, 1 # increment the word pointer.			    	     	  		     	  				    	     	  		     	  				    	     	  		     	  				    	     	  		     	  	
  		addiu $s6, $s6, 1 # incremenet the word length
  		addiu $s2, $s2, 1 # increment the array pointer
  		j counter_loop 
  		check_counter:
  		beq $s3, $t0, restore_word # if the code equlas the line number, then the word found
  		addiu $s3, $s3, 1 # increment the counter.
  		li $s6, 0 # reset word length
  		la $s4, corresponding_word # reset word buffer.
  		addiu $s2, $s2, 1 # increment array pointer.
  		j counter_loop
  		
  		
  	restore_word:
  		sb $zero, ($s4)	# terminate the word
		# now write the word into the output file.
		li $v0 ,15 # system call for write into a file.
		move $a0, $s0 # file descriptor
		la $a1, corresponding_word # address of the word to be print	
  		move $a2, $s6 # length of the word.
  		syscall
  		
  		# add space after the word printed
  		li $v0, 15
  		move $a0, $s0
  		la $a1, space
  		li $a2, 1
  		syscall
    		# read next code from the array of codes.
  		j next_code
  												

compression_ratio:

    # Count characters
    move $t0, $zero       # Initialize character count
    la $t1, file_content # load the content of the uncompressed file
count_chars:
    lb $t3,($t1)  # Load a byte from the buffer

    beqz $t3, next        
    addi $t0, $t0, 1     # Increment character count
    addi $t1, $t1, 1	 # increment the buffer index.
    j count_chars
	
    next: # to count number of codes appears after copmression process.
    la $s1, codes_array
    move $s2, $zero # initialize number of codes.
    count_codes:
    	lb $t2, ($s1)	
    	beqz $t2, ratio_calculate
    	addi $s2, $s2, 1 # increment codes count.
    	addi $s1, $s1, 1 # increment array pointer.
	j count_codes    																				  																						
  	
  	ratio_calculate:
  	# Multiply by 2
	sll $s2, $s2, 1

	# Subtract 1
	addi $s2, $s2, -12

    	# Convert dividend to floating-point
    	mtc1 $t0, $f0

    	# Convert divisor to floating-point
    	mtc1 $s2, $f1

    	# Perform division
    	div.s $f2, $f0, $f1

	li $v0, 4
	la $a0, result_message
	syscall
    	# Print result
    	li $v0, 2               # Print float syscall code
    	mov.s $f12, $f2         # Move result to $f12
    	syscall
    		
	j full_exit																																								
	
																																																																																	
read_compressed_file:
	li $v0, 13
  	la $a0, compressed_path
  	li $a1, 0
  	syscall
  	move $s0, $v0  # save file descriptor in $s0

  	# Check if file was opened successfully
  	bltz $s0, error

	# Read content of file
	li $v0, 14
	move $a0, $s0
	la $a1, compressed_content
	li $a2, 2096
	syscall

	la $t0, compressed_content
	read_compressed:
		lh $t1, ($t0)      # Load a halfword from the buffer
		beqz $t1, full_exit
		la $t2, newline
		beq $t1, $t2, skip
		li $v0, 1
		move $a0, $t1
		syscall
		skip:
		addiu $t0, $t0, 2  # Increment the pointer by 2 bytes (halfword size)
		j read_compressed
										
full_exit:
  # Print bye message
  li $v0, 4
  la $a0, bye_message
  syscall
  # Exit program
  li $v0, 10
  syscall
error2:
  # Print error message
  li $v0, 4
  la $a0, error_message2
  syscall
  j main
  # Exit program
  li $v0, 10
  syscall
error:
  # Print error message
  li $v0, 4
  la $a0, error_message
  syscall
  j main
  # Exit program
  li $v0, 10
  syscall
