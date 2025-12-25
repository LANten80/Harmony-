package com.example.workordersystem.repository;

import com.example.workordersystem.entity.UserToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * 用户Token数据访问层
 */
@Repository
public interface UserTokenRepository extends JpaRepository<UserToken, Long> {

    /**
     * 根据Token查找
     */
    Optional<UserToken> findByToken(String token);

    /**
     * 根据用户ID查找所有Token
     */
    java.util.List<UserToken> findByUserId(String userId);

    /**
     * 删除过期的Token
     */
    @Modifying
    @Query("DELETE FROM UserToken t WHERE t.expireTime < :now")
    void deleteExpiredTokens(@Param("now") LocalDateTime now);

    /**
     * 删除用户的所有Token
     */
    @Modifying
    void deleteByUserId(String userId);
}

