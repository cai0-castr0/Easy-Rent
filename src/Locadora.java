import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class Locadora {

    private static final String URL = "jdbc:postgresql://localhost:5432/Easy_Rent";
    private static final String USER = "postgres";
    private static final String PASSWORD = "Astro@0712";

    private static Connection conectar() {
        Connection conexao = null;
        try {
            conexao = DriverManager.getConnection(URL, USER, PASSWORD);
        } catch (SQLException e) {
            System.err.println("\n#################################################");
            System.err.println("ERRO DE CONEXÃO: Não foi possível conectar ao banco de dados!");
            System.err.println("Verifique se o serviço PostgreSQL está rodando e se a URL/Credenciais estão corretas.");
            System.err.println("Mensagem do SQLState: " + e.getSQLState());
            System.err.println("Detalhes: " + e.getMessage());
            System.err.println("#################################################\n");
        }
        return conexao;
    }

    public static void inserirCliente(String cpf, String nome, String cnh, String telefone, String email) {
        String sql = "INSERT INTO Cliente (cpf, nome, cnh, telefone, email) VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            if (conn == null) return;

            pstmt.setString(1, cpf);
            pstmt.setString(2, nome);
            pstmt.setString(3, cnh);
            pstmt.setString(4, telefone);
            pstmt.setString(5, email);

            int linhasAfetadas = pstmt.executeUpdate();

            if (linhasAfetadas > 0) {
                System.out.println("Cliente '" + nome + "' inserido com sucesso!");
            } else {
                System.out.println("Nenhuma linha afetada. Verifique os dados.");
            }

        } catch (SQLException e) {
            System.err.println("Erro ao inserir cliente: " + e.getMessage());
        }
    }


    public static void listarClientesComLocacoes() {
        String sql = "SELECT C.nome AS Cliente, CR.modelo AS Carro, L.data_retirada " +
                "FROM Cliente C " +
                "JOIN Locacao L ON C.id_cliente = L.id_cliente " +
                "JOIN Carro CR ON L.id_carro = CR.id_carro " +
                "ORDER BY C.nome, L.data_retirada";

        System.out.println("\n=================================================");
        System.out.println("Consulta de Clientes com Locações Ativas");
        System.out.println("=================================================");

        try (Connection conn = conectar();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            if (conn == null) return;

            if (!rs.isBeforeFirst()) {
                System.out.println("Nenhuma locação encontrada no sistema.");
                return;
            }

            while (rs.next()) {
                String nomeCliente = rs.getString("Cliente");
                String modeloCarro = rs.getString("Carro");
                String dataRetirada = rs.getDate("data_retirada").toString();


                System.out.printf("  Cliente: %-20s | Carro: %-20s | Retirada: %s\n",
                        nomeCliente, modeloCarro, dataRetirada);
            }

        } catch (SQLException e) {
            System.err.println("Erro ao listar clientes com locações: " + e.getMessage());
        }
        System.out.println("=================================================\n");
    }

    public static void atualizarTelefoneCliente(int idCliente, String novoTelefone) {
        String sql = "UPDATE Cliente SET telefone = ? WHERE id_cliente = ?";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            if (conn == null) return;

            pstmt.setString(1, novoTelefone);
            pstmt.setInt(2, idCliente);

            int linhasAfetadas = pstmt.executeUpdate();

            if (linhasAfetadas > 0) {
                System.out.println("Telefone do Cliente ID " + idCliente + " alterado para: " + novoTelefone);
            } else {
                System.out.println("Cliente ID " + idCliente + " não encontrado ou telefone já estava atualizado.");
            }

        } catch (SQLException e) {
            System.err.println("Erro ao atualizar telefone: " + e.getMessage());
        }
    }

    public static void deletarCliente(int idCliente) {
        String sql = "DELETE FROM Cliente WHERE id_cliente = ?";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            if (conn == null) return;

            pstmt.setInt(1, idCliente);

            int linhasAfetadas = pstmt.executeUpdate();

            if (linhasAfetadas > 0) {
                System.out.println("Cliente ID " + idCliente + " excluído com sucesso.");
            } else {
                System.out.println("Cliente ID " + idCliente + " não encontrado.");
            }

        } catch (SQLException e) {
            System.err.println("Erro ao deletar cliente (ID " + idCliente + "): " + e.getMessage());
        }
    }

    public static void main(String[] args) {

        System.out.println("--- CREATE ---");
        inserirCliente("22233344455", "Novo Cliente Teste", "11223344556", "5531987654321", "novo.teste@email.com");
        int idClienteTeste = 3;

        System.out.println("\n--- UPDATE ---");
        atualizarTelefoneCliente(idClienteTeste, "559988776655");
        listarClientesComLocacoes();


        System.out.println("\n--- DELETE ---");
        deletarCliente(idClienteTeste);
        deletarCliente(idClienteTeste);
    }
}