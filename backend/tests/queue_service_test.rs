use kks_online_backend::models::{QueuedAction, VariantSelectionActionData};
use kks_online_backend::services::QueueService;

fn sample_action(name: &str) -> QueuedAction {
    QueuedAction {
        action_type: "add_to_cart".to_string(),
        product_name: name.to_string(),
        quantity: 1,
        session_id: Some("sess-1".to_string()),
        customer_id: None,
        timestamp: 0,
    }
}

#[test]
fn queue_tracks_pending_count() {
    let service = QueueService::new();
    let queue_id = "sess-1_0".to_string();

    service
        .create_queue(
            queue_id.clone(),
            vec![sample_action("A"), sample_action("B")],
        )
        .unwrap();

    assert_eq!(service.pending_count(&queue_id).unwrap(), 2);
    assert!(service.has_pending(&queue_id).unwrap());
}

#[test]
fn pop_next_action_drains_queue_in_order() {
    let service = QueueService::new();
    let queue_id = "sess-1_0".to_string();

    service
        .create_queue(
            queue_id.clone(),
            vec![sample_action("First"), sample_action("Second")],
        )
        .unwrap();

    let first = service.pop_next_action(&queue_id).unwrap().unwrap();
    assert_eq!(first.product_name, "First");
    assert_eq!(service.pending_count(&queue_id).unwrap(), 1);

    let second = service.pop_next_action(&queue_id).unwrap().unwrap();
    assert_eq!(second.product_name, "Second");
    assert!(!service.has_pending(&queue_id).unwrap());
}

#[test]
fn lock_and_unlock_queue() {
    let service = QueueService::new();
    let queue_id = "lock-test".to_string();

    service
        .create_queue(queue_id.clone(), vec![sample_action("Item")])
        .unwrap();

    assert!(service.lock_queue(&queue_id).unwrap());
    assert!(service.is_locked(&queue_id).unwrap());
    assert!(!service.lock_queue(&queue_id).unwrap());

    service.unlock_queue(&queue_id).unwrap();
    assert!(!service.is_locked(&queue_id).unwrap());
}

#[test]
fn guest_cart_merges_duplicate_variants() {
    let service = QueueService::new();
    let session = "guest-session";

    service.add_to_guest_cart(session, 10, 2).unwrap();
    service.add_to_guest_cart(session, 10, 3).unwrap();

    let cart = service.get_guest_cart(session).unwrap();
    assert_eq!(cart.len(), 1);
    assert_eq!(cart[0].variant_id, 10);
    assert_eq!(cart[0].quantity, 5);
}

#[test]
fn guest_cart_update_removes_item_when_quantity_zero() {
    let service = QueueService::new();
    let session = "guest-session";

    service.add_to_guest_cart(session, 7, 2).unwrap();
    assert!(service.update_guest_cart_item(session, 7, 0).unwrap());

    let cart = service.get_guest_cart(session).unwrap();
    assert!(cart.is_empty());
}

#[test]
fn set_current_action_locks_queue() {
    let service = QueueService::new();
    let queue_id = "variant-queue".to_string();

    service
        .create_queue(queue_id.clone(), vec![sample_action("Pizza")])
        .unwrap();

    service
        .set_current_action(
            &queue_id,
            VariantSelectionActionData {
                product_id: 1,
                product_name: "Pizza".to_string(),
                quantity: 1,
                session_id: Some("sess".to_string()),
                customer_id: None,
                available_variants: vec![],
                queue_info: None,
            },
        )
        .unwrap();

    assert!(service.is_locked(&queue_id).unwrap());
    service.clear_current_action(&queue_id).unwrap();
    assert!(!service.is_locked(&queue_id).unwrap());
}

#[test]
fn clear_queue_removes_all_state() {
    let service = QueueService::new();
    let queue_id = "clear-me".to_string();

    service
        .create_queue(queue_id.clone(), vec![sample_action("X")])
        .unwrap();
    service.clear_queue(&queue_id).unwrap();

    assert_eq!(service.pending_count(&queue_id).unwrap(), 0);
    assert!(service.get_queue(&queue_id).unwrap().is_none());
}
