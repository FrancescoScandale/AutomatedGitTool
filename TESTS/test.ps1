set-psdebug -trace 1 # Used to show in the command line the executed commands

# Using "" when typing a string is actually mandatory only if there are whitespaces.
# If the string is made by one word/string without interruptions, can use that directly

# INITIAL SET-UP (everything placed inside the "test" directory)
new-item -name "test" -itemtype "directory" 
set-location "test"


# COMMANDS
# Create a new directory
#new-item -name "testInside" -itemtype "directory"
#get-childitem
#remove-item "testInside"

# Create file
new-item -name "file.txt" -itemtype "file"
#get-childitem

# Set a variable
set-variable -name "var" -value "write"
#get-variable -name "var" # Writes the variable object
#write-output $var # Writes only the variable value
#$newVar = read-host "Enter the value to be read"
#write-output $newVar

# Create some files to operate on them
new-item -name "write.txt" -itemtype "file"
new-item -name "writeInside.txt" -itemtype "file"
new-item -name "example.txt" -itemtype "file"
new-item -name "read.txt" -itemtype "file"
new-item -name "writNot.txt" -itemtype "file"
get-childitem

# Write $something into the files whose title contains "write"
$arr = get-childitem -name #only gets the names of the files in the current directory
$something = "This is something to be written in the file"
foreach ($file in $arr){
    #get-member -inputobject file -MemberType method #get all the available methods for the object
    get-variable -name file -valueonly ##print only the names of those files
    #write-output $file
    #if($file.contains("write")){   #check if a string contains another (using methods)
    if($file -like "*write*"){  #check if a string contains another (using regular expressions)
        #write-output "SI - $file"
        "$something $file" | set-content -path $file -encoding utf8
    } else {
        #write-output "NO - $file"
    }
}

# For cycle to remove all the files whose title doesn't contain "write"
foreach ($file in $arr){
    if(!($file -like "*$var*")){  #check if a string contains another (using regular expressions)
        remove-item $file
    }
}
get-childitem

# CLEAN-UP
set-location ..
remove-item "test" -force -recurse