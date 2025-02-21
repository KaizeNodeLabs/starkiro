use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
};

use simple_contract_with_events::simple_contract_with_events::{
    SpyEventsChecker, ISpyEventsCheckerDispatcher, ISpyEventsCheckerDispatcherTrait,
};

#[test]
fn test_simple_assertions() {
    let contract = declare("SpyEventsChecker").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    let dispatcher = ISpyEventsCheckerDispatcher { contract_address };

    let mut spy = spy_events();

    dispatcher.emit_one_event(123);

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    SpyEventsChecker::Event::FirstEvent(
                        SpyEventsChecker::FirstEvent { some_data: 123 },
                    ),
                ),
            ],
        );
}
