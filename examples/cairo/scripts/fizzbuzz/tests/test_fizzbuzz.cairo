use fizzbuzz::fizz_buzz;

#[test]
fn fizzbuzz_test_n3() {
    let mut result = fizz_buzz::fizzbuzz(3);
    assert(*result[0] == '1', 'First element should be 1');
    assert(*result[1] == '2', 'Second element should be 2');
    assert(*result[2] == 'Fizz', 'Third element should be Fizz');
}

#[test]
fn fizzbuzz_test_n5() {
    let result = fizz_buzz::fizzbuzz(5);
    assert(*result[0] == '1', 'First element should be 1');
    assert(*result[1] == '2', 'Second element should be 2');
    assert(*result[2] == 'Fizz', 'Third element should be Fizz');
    assert(*result[3] == '4', 'Fourth element should be 4');
    assert(*result[4] == 'Buzz', 'Fifth element should be Buzz');
}

#[test]
fn fizzbuzz_test_n15() {
    let result = fizz_buzz::fizzbuzz(15);
    assert(*result[0] == '1', 'Element at index 0');
    assert(*result[1] == '2', 'Element at index 1');
    assert(*result[2] == 'Fizz', 'Element at index 2');
    assert(*result[3] == '4', 'Element at index 3');
    assert(*result[4] == 'Buzz', 'Element at index 4');
    assert(*result[5] == 'Fizz', 'Element at index 5');
    assert(*result[6] == '7', 'Element at index 6');
    assert(*result[7] == '8', 'Element at index 7');
    assert(*result[8] == 'Fizz', 'Element at index 8');
    assert(*result[9] == 'Buzz', 'Element at index 9');
    assert(*result[10] == '11', 'Element at index 10');
    assert(*result[11] == 'Fizz', 'Element at index 11');
    assert(*result[12] == '13', 'Element at index 12');
    assert(*result[13] == '14', 'Element at index 13');
    assert(*result[14] == 'FizzBuzz', 'Element at index 14');
}
