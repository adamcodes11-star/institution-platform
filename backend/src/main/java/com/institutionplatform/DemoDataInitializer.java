package com.institutionplatform;

import java.time.LocalDateTime;

import org.springframework.boot.CommandLineRunner;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import com.institutionplatform.model.Announcement;
import com.institutionplatform.model.Institution;
import com.institutionplatform.model.InstitutionEvent;
import com.institutionplatform.repository.AnnouncementRepository;
import com.institutionplatform.repository.InstitutionEventRepository;
import com.institutionplatform.repository.InstitutionRepository;

/**
 * Sample records for portfolio reviewers. Only runs when the "demo" profile
 * is explicitly enabled. Never enable this profile against a real database.
 * All names, contacts and content below are fictional.
 */
@Configuration
@Profile("demo")
public class DemoDataInitializer {

    @Bean
    CommandLineRunner seedDemoData(InstitutionRepository institutions,
                                   AnnouncementRepository announcements,
                                   InstitutionEventRepository events,
                                   @Value("${spring.datasource.url}") String databaseUrl) {
        return args -> {
            DemoSafety.requireLocalDemoDatabase(databaseUrl);
            // Do not overwrite or mix with an already populated database.
            if (institutions.count() != 0) {
                System.out.println("[Demo] Database already contains institutions; no demo records added.");
                return;
            }

            Institution learningCenter = new Institution(
                    "BrightPath Learning Center", "Example City");
            learningCenter.setType("Education");
            learningCenter.setDescription("A fictional learning center used to demonstrate the platform.");
            learningCenter.setCoverTitle("Welcome to BrightPath Learning Center");
            learningCenter.setCoverDescription("Discover hands-on courses, workshops, and community events.");
            learningCenter.setEmail("learning@example.com");
            learningCenter.setWebsiteUrl("https://example.com");
            learningCenter = institutions.save(learningCenter);

            Institution communityCenter = new Institution(
                    "Community Bridge Foundation", "Sample Town");
            communityCenter.setType("Community");
            communityCenter.setDescription("A fictional community organization created for portfolio testing.");
            communityCenter.setCoverTitle("Connecting People Through Community Events");
            communityCenter.setCoverDescription("Explore announcements, activities, and upcoming events.");
            communityCenter.setEmail("community@example.com");
            communityCenter = institutions.save(communityCenter);

            LocalDateTime now = LocalDateTime.now();
            announcements.save(new Announcement(
                    "Workshop Registration Is Open", "Sign up for introductory programming and design workshops.",
                    null, now.minusDays(1), now.plusDays(21), true, learningCenter, null));
            announcements.save(new Announcement(
                    "Important Update for Participants", "Please review the updated activity schedule for this week.",
                    null, now.minusDays(2), now.plusDays(14), true, learningCenter, null));
            announcements.save(new Announcement(
                    "Upcoming Volunteer Day", "Join our upcoming community volunteer day and meet fellow members.",
                    null, now.minusHours(1), now.plusDays(30), true, communityCenter, null));

            events.save(new InstitutionEvent(
                    "Introduction to Programming Workshop", "A beginner-friendly workshop covering basic programming concepts.",
                    "Training Hall", now.plusDays(5), now.plusDays(5).plusHours(2),
                    learningCenter, null));
            events.save(new InstitutionEvent(
                    "Community Networking Meetup", "Meet the team and learn about upcoming community projects.",
                    "Main Hall", now.plusDays(8), now.plusDays(8).plusHours(2),
                    communityCenter, null));

            System.out.println("[Demo] Created 2 fictional institutions, 3 announcements and 2 events.");
        };
    }
}
