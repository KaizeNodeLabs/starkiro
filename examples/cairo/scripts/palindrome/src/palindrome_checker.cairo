fn palindrome_checker(word: ByteArray) -> bool {

    let mut i:u32 = word.len();
    let mut u:u32 = 0;
    let mut flag:bool = false;

    while i > 0 {

        i -= 1;

        if word.at(u).unwrap() != word.at(i).unwrap() {
            flag = false;
            break;
        }else{
            flag = true;
            u += 1;
        }
    }

    flag
}

fn main(){

    println!("Palindromes \n");
    let pal_word_1 = "anna";
    let pal_word_2 = "dewed";
    println!("The word {} is palindrome - [{}]",pal_word_1, palindrome_checker(pal_word_1));
    println!("The word {} is palindrome - [{}]",pal_word_2, palindrome_checker(pal_word_2));


    println!("\nNot palindromes \n");
    let pal_word_1 = "taco";
    let pal_word_2 = "mother";
    println!("The word {} is not palindrome - [{}]",pal_word_1, palindrome_checker(pal_word_1));
    println!("The word {} is not palindrome - [{}]",pal_word_2, palindrome_checker(pal_word_2));

}