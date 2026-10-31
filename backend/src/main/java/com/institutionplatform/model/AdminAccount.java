package com.institutionplatform.model;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "admin_accounts")
public class AdminAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    private String email;

    private String passwordHash;

    @Enumerated(EnumType.STRING)
    private AdminRole role;

    @OneToOne
    @JoinColumn(name = "institution_id", unique = true)
    private Institution institution;

    public AdminAccount() {
    }

    public AdminAccount(
            String name,
            String email,
            String passwordHash,
            AdminRole role,
            Institution institution) {

        this.name = name;
        this.email = email;
        this.passwordHash = passwordHash;
        this.role = role;
        this.institution = institution;
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public AdminRole getRole() {
        return role;
    }

    public Institution getInstitution() {
        return institution;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public void setRole(AdminRole role) {
        this.role = role;
    }

    public void setInstitution(Institution institution) {
        this.institution = institution;
    }
}
