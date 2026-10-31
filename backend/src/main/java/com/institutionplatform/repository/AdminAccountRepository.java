package com.institutionplatform.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.institutionplatform.model.AdminAccount;

public interface AdminAccountRepository
        extends JpaRepository<AdminAccount, Long> {

    Optional<AdminAccount> findByEmail(String email);

    boolean existsByEmail(String email);

    boolean existsByInstitutionId(Long institutionId);
}
