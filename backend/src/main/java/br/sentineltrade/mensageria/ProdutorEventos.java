package br.sentineltrade.mensageria;

import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

/**
 * Publica eventos de ordem na fila. RT01, RF06.
 */
@Component
public class ProdutorEventos {

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public ProdutorEventos(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void publicarOrdemValidada(Object eventoOrdem) {
        kafkaTemplate.send("topico-ordens-validadas", eventoOrdem);
    }
}