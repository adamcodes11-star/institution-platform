package com.institutionplatform.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.institutionplatform.model.InstitutionEvent;

public interface InstitutionEventRepository
        extends JpaRepository<InstitutionEvent, Long> {

    List<InstitutionEvent> findByInstitutionIdOrderByStartAtAsc(Long institutionId);

    List<InstitutionEvent>
    findByInstitutionIdAndEndAtGreaterThanEqualOrderByStartAtAsc(
            Long institutionId,
            LocalDateTime now);

    Optional<InstitutionEvent> findByIdAndInstitutionId(
            Long id,
            Long institutionId);

    boolean existsByInstitutionId(Long institutionId);

    boolean existsByCreatedById(Long adminId);
}
