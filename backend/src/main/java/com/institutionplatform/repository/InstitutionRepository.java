package com.institutionplatform.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.institutionplatform.model.Institution;

public interface InstitutionRepository
        extends JpaRepository<Institution, Long> {

    List<Institution> findByNameContainingIgnoreCase(String name);

    List<Institution> findByCityContainingIgnoreCase(String city);

    List<Institution> findByTypeContainingIgnoreCase(String type);

    List<Institution> findByNameContainingIgnoreCaseAndCityContainingIgnoreCase(
            String name,
            String city);
}
