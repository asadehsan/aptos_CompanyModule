module CompanyModule::EmployeeTracker {
    use std::string::{String};
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::signer;
    use aptos_framework::event;
    
    /// Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_NOT_REGISTERED: u64 = 2;
    
    /// Structure to store employee information and access rights
    struct EmployeeRecord has key, store {
        employee_id: String,
        authorized_projects: vector<String>,
        last_check_in: u64,
        last_check_out: u64,
        is_present: bool
    }
    
    /// Event structure for tracking entry/exit
    #[event]
    struct AccessEvent has drop, store {
        employee_id: String,
        project_id: String,
        timestamp: u64,
        is_entry: bool
    }

    /// Register an employee and their project access
    public entry fun register_employee(
        admin: &signer,
        employee_address: address,
        employee_id: String,
        projects: vector<String>
    ) {
        // Only company admin can register employees
        assert!(signer::address_of(admin) == @CompanyModule, E_NOT_AUTHORIZED);
        
        let employee_record = EmployeeRecord {
            employee_id,
            authorized_projects: projects,
            last_check_in: 0,
            last_check_out: 0,
            is_present: false
        };
        
        move_to(admin, employee_record);
    }
    
    /// Track employee entry/exit and verify project access
    public entry fun track_access(
        employee: &signer,
        project_id: String,
        is_entry: bool
    ) acquires EmployeeRecord {
        let employee_addr = signer::address_of(employee);
        assert!(exists<EmployeeRecord>(employee_addr), E_NOT_REGISTERED);
        
        let record = borrow_global_mut<EmployeeRecord>(employee_addr);
        let current_time = timestamp::now_seconds();
        
        // Verify project access authorization
        let authorized = false;
        let i = 0;
        let len = vector::length(&record.authorized_projects);
        
        while (i < len) {
            if (vector::borrow(&record.authorized_projects, i) == &project_id) {
                authorized = true;
                break;
            };
            i = i + 1;
        };
        
        assert!(authorized, E_NOT_AUTHORIZED);
        
        // Update check-in/check-out times and status
        if (is_entry) {
            record.last_check_in = current_time;
            record.is_present = true;
        } else {
            record.last_check_out = current_time;
            record.is_present = false;
        };
        
        // Emit event for tracking
        event::emit(AccessEvent {
            employee_id: record.employee_id,
            project_id,
            timestamp: current_time,
            is_entry
        });
    }
}