package br.sentineltrade.comum;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Configuracao minima de seguranca: apenas /actuator/health e publico.
 * Todo o resto exige autenticacao.
 *
 * TODO: adicionar filtro JWT, perfis (INVESTIDOR, AUDITOR, ADMIN) e MFA.
 */
@Configuration
public class SecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable) // API stateless; revisar ao implementar JWT
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health").permitAll()
                .anyRequest().authenticated());
        return http.build();
    }
}
