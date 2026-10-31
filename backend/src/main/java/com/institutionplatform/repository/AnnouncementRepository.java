package com.institutionplatform.repository;

import java.time.LocalDateTime;
import java.util.List;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.institutionplatform.model.Announcement;

public interface AnnouncementRepository
        extends JpaRepository<Announcement, Long> {

    List<Announcement> findByInstitutionId(Long institutionId);

    List<Announcement>
    findByInstitutionIdAndStartAtLessThanEqualAndEndAtGreaterThanEqual(
            Long institutionId,
            LocalDateTime startTime,
            LocalDateTime endTime
    );
    Optional<Announcement> findByIdAndInstitutionId(
            Long id,
            Long institutionId);

    boolean existsByCreatedById(Long adminId);

    boolean existsByInstitutionId(Long institutionId);
}
