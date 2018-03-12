# Assignment 5 - Shellcode Analysis

Man, I've been slacking. It's currently 8:45PM, I'm sipping on some sweet Colombian medium-roast coffee, and it's way too late for that. I've gotta get this SLAE wrapped up though! So let's jump into assignment 5, which is all about analyzing third-party shellcode.

## Problem Statement

* Take up at least 3 shellcode samples created using Msfpayload for linux/x86
* Use GDB/Ndisasm/Libemu to dissect the functionality of the shellcode
* Present your analysis


## Doing Work

There's not a whole lot of purpose in fully populating this readme with the details of how I did this assignment. I'll outline the process I followed when generating the files, but then I'll let my analysis files included in this project do most of the talking. If you have any questions, please feel free to navigate to [my blog](https://coffeegist.com/) and leave a comment!

#### Generating the Files

We only need to do two things for this assignment. The first is to generate a payload using *msfvenom*. Once we have our shellcode in it's raw form, I chose to use *ndisasm* to do my analysis, because this is the only method that doesn't execute any of the code to be analyzed (simulated or not). To accomplish these two tasks, I used the following commands (example - staged_reverse_tcp):

```bash
root@kali:~/courses/slae/exam/assignment5# msfvenom -p linux/x86/shell/reverse_tcp -a x86 --platform linux > staged_reverse_tcp.raw

root@kali:~/courses/slae/exam/assignment5# ndisasm -b 32 staged_reverse_tcp.raw > staged_reverse_tcp_analyzed.ndisasm
```

Once we have the ndisasm'ed file, we can read the assembly line-by-line to understand what's happening.

## Wrapping Up

As I mentioned before, I'm going to let the comments in my ndisasm'ed files do the explanations here! If you want a more in-depth look, or have questions, head over to [https://coffeegist.com/](https://coffeegist.com/) and leave a comment! Until next time, happy hacking!


###### SLAE Exam Statement

This blog post has been created for completing the requirements of the SecurityTube Linux Assembly Expert certification:

http://securitytube-training.com/online-courses/securitytube-linux-assembly-expert/

Student ID: SLAE-1158
