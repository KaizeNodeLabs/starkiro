use queue_data_structure::queue::{Queue, QueueImpl, DestructQueue};

#[test]
fn test_new_queue() {
    let mut queue: Queue<u32> = QueueImpl::new();
    assert_eq!(queue.size(), 0);
    assert!(queue.is_empty());
}

#[test]
fn test_enqueue() {
    let mut queue: Queue<u32> = QueueImpl::new();
    queue.enqueue(1);
    queue.enqueue(2);
    assert_eq!(queue.size(), 2);
}

#[test]
fn test_dequeue() {
    let mut queue: Queue<u32> = QueueImpl::new();
    queue.enqueue(1);
    queue.enqueue(2);
    assert_eq!(queue.dequeue(), Option::Some(1));
    assert_eq!(queue.dequeue(), Option::Some(2));
}

#[test]
fn test_dequeue_when_empty() {
    let mut queue: Queue<u32> = QueueImpl::new();
    assert_eq!(queue.dequeue(), Option::None);
}

#[test]
fn test_front() {
    let mut queue: Queue<u32> = QueueImpl::new();
    queue.enqueue(1);
    queue.enqueue(2);
    assert_eq!(queue.front(), Option::Some(1));
    queue.dequeue();
    assert_eq!(queue.front(), Option::Some(2));
}

#[test]
fn test_front_when_empty() {
    let mut queue: Queue<u32> = QueueImpl::new();
    assert_eq!(queue.front(), Option::None);
}

#[test]
fn test_real_world_usecase() {
    let mut queue: Queue<u32> = QueueImpl::new();
    for i in 0..100_u32 {
        queue.enqueue(i);
    };
    for i in 0..100_u32 {
        assert_eq!(queue.dequeue(), Option::Some(i));
    };
    for i in 0..50_u32 {
        queue.enqueue(i);
    };
    for i in 0..50_u32 {
        assert_eq!(queue.dequeue(), Option::Some(i));
    };
}

#[test]
fn test_destruct() {
    let mut queue: Queue<u32> = QueueImpl::new();
    queue.enqueue(1);
    queue.enqueue(2);
    queue.destruct();
}
