import 'dart:io';
import 'dart:math';

const int boardSize = 10;
const List<int> shipSizes = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];

enum CellState { empty, ship, hit, miss }

class Board {
  List<List<CellState>> grid =
      List.generate(boardSize, (_) => List.filled(boardSize, CellState.empty));

  bool canPlaceShip(int x, int y, int size, bool horizontal) {
    if (horizontal) {
      if (x + size > boardSize) return false;
    } else {
      if (y + size > boardSize) return false;
    }

    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= size; dx++) {
        int cx = x + (horizontal ? dx : dy);
        int cy = y + (horizontal ? dy : dx);
        if (cx >= 0 && cx < boardSize && cy >= 0 && cy < boardSize) {
          if (grid[cy][cx] != CellState.empty) return false;
        }
      }
    }

    return true;
  }

  bool placeShip(int x, int y, int size, bool horizontal) {
    if (!canPlaceShip(x, y, size, horizontal)) {
      return false;
    }

    for (int i = 0; i < size; i++) {
      int cx;
      int cy;

      if (horizontal) {
        cx = x + i;
        cy = y;
      } else {
        cx = x;
        cy = y + i;
      }

      grid[cy][cx] = CellState.ship;
    }

    return true;
  }

  void autoPlaceShips() {
    final rand = Random();
    for (var size in shipSizes) {
      bool placed = false;
      while (!placed) {
        int x = rand.nextInt(boardSize);
        int y = rand.nextInt(boardSize);
        bool horizontal = size == 1 ? true : rand.nextBool();
        placed = placeShip(x, y, size, horizontal);
      }
    }
  }

  bool receiveShot(int x, int y) {
    if (grid[y][x] == CellState.ship) {
      grid[y][x] = CellState.hit;
      return true;
    } else if (grid[y][x] == CellState.empty) {
      grid[y][x] = CellState.miss;
    }
    return false;
  }

  bool allShipsSunk() {
    for (var row in grid) {
      for (var cell in row) {
        if (cell == CellState.ship) return false;
      }
    }
    return true;
  }

  void printBoard({bool hideShips = false}) {
    stdout.write('  ');
    for (int i = 0; i < boardSize; i++) {
      stdout.write('$i ');
    }
    stdout.writeln();
    for (int y = 0; y < boardSize; y++) {
      stdout.write('$y ');
      for (int x = 0; x < boardSize; x++) {
        var cell = grid[y][x];
        String symbol;
        switch (cell) {
          case CellState.empty:
            symbol = '.';
            break;
          case CellState.ship:
            symbol = hideShips ? '.' : 'O';
            break;
          case CellState.hit:
            symbol = 'X';
            break;
          case CellState.miss:
            symbol = '*';
            break;
        }
        stdout.write('$symbol ');
      }
      stdout.writeln();
    }
  }
}

class Game {
  Board playerBoard = Board();
  Board computerBoard = Board();
  final rand = Random();

  void start() {
    print('1 — Ручная расстановка');
    print('2 — Автоматическая расстановка');
    stdout.write('Выберите способ расстановки: ');
    var choice = stdin.readLineSync();

    if (choice == '1') {
      _manualPlacement();
    } else {
      print('\nАвтоматическая расстановка кораблей');
      playerBoard.autoPlaceShips();
    }

    computerBoard.autoPlaceShips();

    bool playerTurn = true;
    int playerScore = 0;
    int computerScore = 0;

    while (true) {
      print('\nВаше поле:');
      playerBoard.printBoard();
      print('\nПоле противника:');
      computerBoard.printBoard(hideShips: true);

      if (playerTurn) {
        stdout.write('\nВаш выстрел (x y): ');
        var input = stdin.readLineSync();
        if (input == null || input.isEmpty) continue;
        var parts = input.split(' ');
        if (parts.length != 2) continue;
        int? x = int.tryParse(parts[0]);
        int? y = int.tryParse(parts[1]);
        if (x == null || y == null || x >= boardSize || y >= boardSize) continue;

        bool hit = computerBoard.receiveShot(x, y);
        if (hit) {
          playerScore++;
          print('Попадание');
        } else {
          print('Мимо');
          playerTurn = false;
        }
      } else {
        print('\nХод компьютера...');
        int x = rand.nextInt(boardSize);
        int y = rand.nextInt(boardSize);
        bool hit = playerBoard.receiveShot(x, y);
        if (hit) {
          computerScore++;
          print('Компьютер попал по ($x, $y)!');
        } else {
          print('Компьютер промахнулся.');
          playerTurn = true;
        }
      }

      if (playerBoard.allShipsSunk()) {
        print('\nВсе ваши корабли уничтожены!');
        print('Компьютер победил!');
        break;
      }
      if (computerBoard.allShipsSunk()) {
        print('\nВы победили!');
        break;
      }

      print('\nСчёт: Вы $playerScore — Компьютер $computerScore');
    }
  }

  void _manualPlacement() {
    print('\nРучная расстановка кораблей');
    for (var size in shipSizes) {
      bool placed = false;
      while (!placed) {
        playerBoard.printBoard();
        print('\nРазместите корабль длиной $size.');
        stdout.write('Введите координаты (x y): ');
        var input = stdin.readLineSync();
        if (input == null || input.isEmpty) continue;
        var parts = input.split(' ');
        if (parts.length != 2) continue;
        int? x = int.tryParse(parts[0]);
        int? y = int.tryParse(parts[1]);
        if (x == null || y == null || x < 0 || y < 0 || x >= boardSize || y >= boardSize) {
          print('Неверные координаты!');
          continue;
        }

        bool horizontal = true;
        if (size > 1) {
          stdout.write('Ориентация (h — горизонтально, v — вертикально): ');
          var orient = stdin.readLineSync();
          horizontal = orient?.toLowerCase() != 'v';
        }

        if (playerBoard.placeShip(x, y, size, horizontal)) {
          print('Корабль установлен.');
          placed = true;
        } else {
          print('Нельзя разместить корабль здесь.');
        }
      }
    }
    print('\nВсе корабли расставлены!');
  }
}

void main() {
  Game().start();
}
