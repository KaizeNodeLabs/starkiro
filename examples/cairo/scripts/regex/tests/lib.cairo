#[cfg(test)]
mod tests {
    use regex::fib;

    #[test]
    fn it_works() {
        assert(fib(16) == 987, 'it works!');
    }
}
