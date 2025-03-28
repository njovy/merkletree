import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:merkletree/merkletree.dart';
import 'package:merkletree/src/utils.dart';
import 'package:pointycastle/digests/sha1.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

Uint8List sha256(Uint8List data) {
  var sha256 = Digest('SHA-256');
  return sha256.process(data);
}

Uint8List sha1(Uint8List data) {
  return SHA1Digest().process(data);
}

Uint8List sha3(Uint8List data) {
  var sha3 = Digest('Keccak/256');
  return sha3.process(data);
}

void main() {
  group('merkeltree', () {
    test('sha1 with sort pairs option', () {
      var leaves = [
        'd89f84d948796605a413e196f40bce1d6294175d',
        '32f04c7f572bf75a266268c6f4d8c92731dc3b7f',
        'b80b52d80f5fe940ac2c987044bc439e4218ac94',
        '1553c75a1d637961827f4904a0955e57915d8310'
      ].map((x) => Uint8List.fromList(hex.decode(x))).toList();

      var tree = MerkleTree(
          leaves: leaves, hashAlgo: sha1, sortPairs: true, sortLeaves: true);
      final leaf = leaves.first;
      final proof = tree.getProof(leaf: leaf);
      print(hex.encode(tree.root));
      expect(true, tree.verify(proof: proof, targetNode: leaf, root: tree.root));

      expect(proof.map((e) => hex.encode(e.data)).toList().join(","), ['b80b52d80f5fe940ac2c987044bc439e4218ac94', '59f544ee5de8d761b124ccd4e1285d3b02a2a539'].join(","));

    });
    test('keccak256 with sort leaves and sort pairs option', () {
      var leaves = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j']
          .map((x) => Uint8List.fromList(x.codeUnits))
          .map((x) => sha3(x))
          .toList();

      var tree = MerkleTree(
          leaves: leaves, hashAlgo: sha3, sortPairs: true, sortLeaves: true);
      expect(hex.encode(tree.root),
          '60219f87561939610b484575e45c6e81156a53b86d7cd16640d930d14f21758e');
    });
    test('sha256 with sort pairs option', () {
      var leaves = ['a', 'b', 'c', 'd', 'e', 'f']
          .map((x) => Uint8List.fromList(x.codeUnits))
          .map((x) => sha256(x))
          .toList();
      var tree = MerkleTree(leaves: leaves, hashAlgo: sha256, sortPairs: true);
      expect(hex.encode(tree.root),
          'a30ba95a1a5dc397fe45ea20105363b08d682b864a28f4940419a29349a28325');
    });
    test('keccak256 with sort leaves and sort pairs option', () {
      var leaves = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j']
          .map((x) => Uint8List.fromList(x.codeUnits))
          .map((x) => sha3(x))
          .toList();
      var tree = MerkleTree(
          leaves: leaves, hashAlgo: sha3, sortPairs: true, sortLeaves: true);
      expect(hex.encode(tree.root),
          '60219f87561939610b484575e45c6e81156a53b86d7cd16640d930d14f21758e');
    });
    test('sha256 - sha3 leaves', () {
      var leaves = ['a', 'b', 'c']
          .map((x) => Uint8List.fromList(x.codeUnits))
          .map((x) => sha3(x))
          .toList();
      var tree = MerkleTree(leaves: leaves, hashAlgo: sha256);
      expect(hex.encode(tree.root),
          '311d2e46f49b15fff8b746b74ad57f2cc9e0d9939fda94387141a2d3fdf187ae');
    });

    test('sha256 - sha256 leaves', () {
      var leaves = ['a', 'b', 'c']
          .map((x) => Uint8List.fromList(x.codeUnits))
          .map((x) => sha256(x))
          .toList();
      var tree = MerkleTree(leaves: leaves, hashAlgo: sha256);
      expect(hex.encode(tree.root),
          '7075152d03a5cd92104887b476862778ec0c87be5c2fa1c0a90f87c49fad6eff');
    });

    test('solidity sha3 [keccak-256]', () {
      var leaves = ['a', 'b', 'c']
          .map((x) => Uint8List.fromList(x.codeUnits))
          .map((x) => sha3(x))
          .toList();

      var a_hash =
          '3ac225168df54212a25c1c01fd35bebfea408fdac2e31ddd6f80a4bbf9a5f1cb';
      var b_hash =
          'b5553de315e0edf504d9150af82dafa5c4667fa618ed0a6f19c69b41166c5510';
      var c_hash =
          '0b42b6393c1f53060fe3ddbfcd7aadcca894465a5a438f69c87d790b2299b9b2';

      expect(leaves.map((x) => hex.encode(x)), [a_hash, b_hash, c_hash]);

      var tree = MerkleTree(leaves: leaves, hashAlgo: sha3);

      var layers = tree.layers.sublist(1); // no leaves

      var layer_1 = hex
          .encode(sha3(MerkleTreeUtils.bufferConcat([leaves[0], leaves[1]])));
      expect(hex.encode(layers[0][0]), layer_1);
      expect(hex.encode(layers[0][1]), c_hash);

      var root = Uint8List.fromList(hex.decode(
          'aff1208e69c9e8be9b584b07ebac4e48a1ee9d15ce3afe20b77a4d29e4175aa3'));
      expect(hex.encode(tree.root), hex.encode(root));

      var proof_0 = tree.getProof(leaf: leaves[0]);
      expect(proof_0.length, 2);
      expect(proof_0[0].position, MerkleProofPosition.right);
      expect(hex.encode(proof_0[0].data), b_hash);
      expect(proof_0[1].position, MerkleProofPosition.right);
      expect(hex.encode(proof_0[1].data), c_hash);

      expect(
          tree.verify(proof: proof_0, targetNode: leaves[0], root: root), true);

      var proof_1 = tree.getProof(leaf: leaves[1]);
      expect(proof_1.length, 2);
      expect(proof_1[0].position, MerkleProofPosition.left);
      expect(hex.encode(proof_1[0].data), a_hash);
      expect(proof_1[1].position, MerkleProofPosition.right);
      expect(hex.encode(proof_1[1].data), c_hash);

      expect(
          tree.verify(proof: proof_1, targetNode: leaves[1], root: root), true);

      var proof_2 = tree.getProof(leaf: leaves[2]);
      expect(proof_2.length, 1);
      expect(proof_2[0].position, MerkleProofPosition.left);
      expect(hex.encode(proof_2[0].data), layer_1);

      expect(
          tree.verify(proof: proof_2, targetNode: leaves[2], root: root), true);
    });

    test('solidity sha3 [keccak-256] with duplicate leaves', () {
      var leaves = ['a', 'b', 'a']
          .map((x) => Uint8List.fromList(x.codeUnits))
          .map((x) => sha3(x))
          .toList();

      var a_hash =
          '3ac225168df54212a25c1c01fd35bebfea408fdac2e31ddd6f80a4bbf9a5f1cb';
      var b_hash =
          'b5553de315e0edf504d9150af82dafa5c4667fa618ed0a6f19c69b41166c5510';

      var tree = MerkleTree(leaves: leaves, hashAlgo: sha3);

      expect(
          leaves.map((x) => hex.encode(x)).toList(), [a_hash, b_hash, a_hash]);

      var root = hex.decode(
          'b8912f7269068901f231a965adfefbc10f0eedcfa61852b103efd54dac7db3d7');
      expect(hex.encode(tree.root), hex.encode(root));

      var layer_1 = hex
          .encode(sha3(MerkleTreeUtils.bufferConcat([leaves[0], leaves[1]])));

      var proof_0 = tree.getProof(leaf: leaves[2], index: 2);
      expect(proof_0.length, 1);
      expect(proof_0[0].position, MerkleProofPosition.left);
      expect(hex.encode(proof_0[0].data), layer_1);
    });

    test('sha-256 with option.isBitcoinTree', () {
      /* Derived from:
     * http://www.righto.com/2014/02/bitcoin-mining-hard-way-algorithms.html
     */
      final txHashes = List.unmodifiable([
        '00baf6626abc2df808da36a518c69f09b0d2ed0a79421ccfde4f559d2e42128b',
        '91c5e9f288437262f218c60f986e8bc10fb35ab3b9f6de477ff0eb554da89dea',
        '46685c94b82b84fa05b6a0f36de6ff46475520113d5cb8c6fb060e043a0dbc5c',
        'ba7ed2544c78ad793ef5bb0ebe0b1c62e8eb9404691165ffcb08662d1733d7a8',
        'b8dc1b7b7ed847c3595e7b02dbd7372aa221756b718c5f2943c75654faf48589',
        '25074ef168a061fcc8663b4554a31b617683abc33b72d2e2834f9329c93f8214',
        '0fb8e311bffffadc6dc4928d7da9e142951d3ba726c8bde2cf1489b62fb9ebc5',
        'c67c79204e681c8bb453195db8ca7d61d4692f0098514ca198ccfd1b59dbcee3',
        'bd27570a6cbd8ad026bfdb8909fdae9321788f0643dea195f39cd84a60a1901b',
        '41a06e53ffc5108358ddcec05b029763d714ae9f33c5403735e8dee78027fe74',
        'cc2696b44cb07612c316f24c07092956f7d8b6e0d48f758572e0d611d1da6fb9',
        '8fc508772c60ace7bfeb3f5f3a507659285ea6f351ac0474a0a9710c7673d4fd',
        '62fed508c095446d971580099f976428fc069f32e966a40a991953b798b28684',
        '928eadbc39196b95147416eedf6f635dcff818916da65419904df8fde977d5db',
        'b137e685df7c1dffe031fb966a0923bb5d0e56f381e730bc01c6d5244cfe47c1',
        'b92207cee1f9e0bfbd797b05a738fab9de9c799b74f54f6b922f20bd5ec23dd6',
        '29d6f37ada0481375b6903c6480a81f8deaf2dcdba03411ed9e8d3e5684d02dd',
        '48158deb116e4fd0429fbbbae61e8e68cb6d0e0c4465ff9a6a990037f88c489c',
        'be64ea86960864cc0a0236bbb11f232faf5b19ae6e2c85518628f5fae37ec1ca',
        '081363552e9fff7461f1fc6663e1abd0fb2dd1c54931e177479a18c4c26260e8',
        'eb87c25dd2b2537b1ff3dbabc420e422e2a801f1bededa6fa49ef7980feaef70',
        '339e16fcc11deb61ccb548239270af43f5ad34c321416bada4b8d66467b1c697',
        '4ad6417a3a04179482ed2e4b7251c396e38841c6fba8d2ce9543337ab7c93c02',
        'c28a45cded020bf424b400ffc9cb6f2f85601934f18c34a4f78283247192056a',
        '882037cc9e3ee6ddc2d3eba86b7ca163533b5d3cbb16eaa38696bb0a2ea1137e',
        '179bb936305b46bb0a9df330f8701984c725a60e063ad5892fa97461570b5c04',
        '9517c585d1578cb327b7988f38e1a15c663955ea288a2292b40d27f232fbb980',
        '2c7e07d0cf42e5520bcbfe2f5ef63761a9ab9d7ccb00ea346195eae030f3b86f',
        '534f631fc42ae2d309670e01c7a0890e4bfb65bae798522ca14df09c81b09734',
        '104643385619adb848593eb668a8066d1f32650edf35e74b0fc3306cb6719448',
        '87ac990808239c768182a752f4f71cd98558397072883c7e137efb49d22b9231',
        '9b3e2f1c47d59a444e9b6dc725f0ac6baf160d22f3a9d399434e5e65b14eccb0',
        'fbe123066ae5add633a542f151663db4eb5a7053e388faadb40240671ae1b09b',
        '1dd07e92e20b3cb9208af040031f7cfc4efd46cc31ec27be20a1047965a42849',
        '2709bb9ed27353c1fd76b9240cab7576a44de68945e256ad44b2cb8d849a8060',
        'd0174db2c712573432a7869c1508f371f3a1058aeedddc1b53a7e04d7c56c725',
        'b4a16f724cddb8f77ddf3d2146a12c4be13d503885eaba3518a03da005009f62',
        '2aa706d75decbe57745e01d46f9f5d30a08dedaf3288cee14cc4948e3684e1d4',
        'ee49c5f6a5129ccaf2abebbc1d6d07a402a600af6221476b89aafaa683ca95b7',
        'bea1011c77874845e9b4c876ed2ceebd530d428dd4a564ad003d9211d40bb091',
        'f1e88ffc2b1de2aa4827002f06943ce5468735f7433f960bf01e75885b9f832b',
        '19247d017e002fb9143d1a89eb921222a94f8a3d0faaf2e05b0f594989edc4c4',
        '13f714ff62ee7d26b6d69ca980c141ebc54e9f71d2697083fe6c5efc1b02bd0f',
        '0c78cbb8246572f015fbdc53dc9798fa54d1119ec77c1f07ac310bcbcc40dbf8',
        '4bcde0ef92a6d24a2be7be50ac5e5299d776df2e6229ba5d475c2491da94f255',
        '0cfd7d1058502730cf0b2ffa880c78ef534651e06832b5d87c0d7eb84eac5b0c',
        '3a168f794d6e0c614429ad874317cc4cd67a8177214880ff6ea1704d29228c2f',
        'f9a555d817334397b402518d6fd959dc73d981ee7f5fe67969b63974ebbef127',
        '24b52691f66eaed4ce391a473902e309018257c98b9f02aaa33b399c9e6f3168',
        'a37b5e623dc26a180d9e2c9510d06885b014e86e533adb63ec40511e10b55046',
        '9dbaeb485e51d9e25a5621dc46e0bc0aaf51fb26be5acc4e370b96f62c469b80',
        'a6431d3d39f6c38c5df48405090752cab03bfdf5c77cf881b18a946807fba74a',
        'faa77e309f125373acf19855dd496fffe2f74962e545420844557a3adc7ebc11',
        '3523f52543ecfea2f78486dc91550fad0e6467d46d9d9c82ca63b2e0230bfa71',
        'a0583e358e42d77d18d1fd0533ff0a65615fc3b3112061ef92f168a00bf640c1',
        '42ae900888d5e5dde59c8e3d06e13db9e84ef05d27726d4b67fd00c50cd9406a',
        '154940777d3ff78f592ef02790131a59263c36b4958bbc836f9a767ea1a9f178',
        '6a0337de6ac75eecf748306e8ebc5bfe5c811a1481ae50f6956a9e7f26a679f5',
        'c99530c2148e09688d0b88795625943371183bf1f5d56c7446c6ed51ea133589',
        '626421dbe8ad6a0fd0d622d5dd3308a1cdc00b98575a41a91fe01a439e6f40bd',
        'b2f3a559f605a158cc395126c3cf394a7e92a53b7514c75157e1dc43a6c7f93e',
        'dffe06d1bea81f2a01c76786404bb867258f9e68013bf25454097ce935090738',
        '0860159ec7a2a51ce107c182a988c40b4bc2057a734354a1219b6c65e72640ed',
        'a405ff1bb51846b1867acc0b0da17f6f9616e592a0a7ff5ef3297c1ecfd60911',
        'a7d451924263284765f6343bca8a21b79b89ebfe611c7355dd88e0ec1c29e232',
        '41c758d08a4d3fe4d90645711589b832a2cd54dd25bd5b66e463e5d389a53aff',
        'a05c1a93a521fa5dbc1790cfbb808893453a428a65f2c6b2d51249fbb12db309',
        '90997920aa9786e10f513cfdd14e294feee6739cee1ab61b3fb1e3f42e7a915d',
        '99fcb9cb62c20a3135484a70bd3f73983f8f3b7b26266dad34f3993958a7642c',
        'e05f9a668b37e5f78bd3b9d047f29f92b33a87f11dd48390410006f858188b7b',
        '56dbc65895f7992da4a6985e7edba4d1c00879f1b28442c644c8a07658ceab27',
        '5e9004fe262b829563d0804656ba68b1de1690401f08a1915273230d8c902fc0',
        '1ea9ed3717523c5e304b7a7ac8058a87fb4f3fed8c6004769f226c9bb67e79c5',
        'f0f1a4c009b3f1b2729e89898e2f5c0fcdc312edea5df884a9c897cb90e4c566',
        'b5bb4ddf04863e6a60f33cb96c20dac8175d3bae55f335781503143c97a50e43',
        'f14cc97a20c6f627b4b78301352ae35463bc359362589cd178a06c0fa90850b7',
        '628801c8f614015c0fa0ccb2768cccc3e7b9d41ceed06071ce2534d31f7236d6',
        '3be1013c8f8da150e2195408093153b55b08b037fd92db8bb5e803f4c2538aae',
        'c9e1f8777685f54ba65c4e02915fd649ee1edcbf9c77ddf584b943d27efb86c3',
        '4274e92ed3bd02eb101baa5fb8ff7b96236830762d08273749fbb5166db8ab0b',
        'aa84c955bea04c7cee8f5bbbec97d25930fcaca363eed1b8cad37b931556d3e3',
        'd6a29c948677fb1f71aaf16debc3d071a4dd349458eb9e056dce3a000ff853da',
        'ba84bdb3d78367ca365016ac4bff9269576eb010f874c2967af73e0de5638de0',
        '1546c79951e3b541bc64d1957b565b7a2850fc87192c7b374aee6cfc69b9805e',
        'f119227d492ebe27fe9aae321980802454dfa64b2691efbe796c5075d5b07f62',
        'b8cf13d64818b32f96bbb585998b1bc9505f6a94055488e5a71fee9479c6f2a9',
        '1aaf459705b6afef2d7b83e3f181f1af55be0813daf55edce104cc59abc28ed7',
        '61ac185c8f520b5e3134953dc52ff292a40e1e96b088dab259558a9d240ec02f',
        '2da96e3154d7ec2329f787b73cb8a436b92d64cf3cc28e920d073279ea73b5f8',
        '1c4d72ce733b971b9ec4e24f37d733355f6f2ea635cc67ffb3e22748484df446',
        '2a6f89769f3272ac8c7a36a42a57627eca6b260ab2c76d8046a27d44d4034893',
        'f8d11df51a2cc113698ebf39a958fe81179d7d973d2044322771c0fe63f4d7c9',
        'f2287f17a4fa232dca5715c24a92f7112402a8101b9a7b276fb8c8f617376b90',
        'bb5ee510a4fda29cae30c97e7eee80569d3ec3598465f2d7e0674c395e0256e9',
        '647ab8c84365620d60f2523505d14bd230b5e650c96dee48be47770063ee7461',
        '34b06018fcc33ba6ebb01198d785b0629fbdc5d1948f688059158f053093f08b',
        'ff58b258dab0d7f36a2908e6c75229ce308d34806289c912a1a5f39a5aa71f9f',
        '232fc124803668a9f23b1c3bcb1134274303f5c0e1b0e27c9b6c7db59f0e2a4d',
        '27a0797cc5b042ba4c11e72a9555d13a67f00161550b32ede0511718b22dbc2c',
      ]);

      var leaves =
          txHashes.map((x) => Uint8List.fromList(hex.decode(x))).toList();

      var tree =
          MerkleTree(leaves: leaves, hashAlgo: sha256, isBitcoinTree: true);

      var root = Uint8List.fromList(hex.decode(
          '871714dcbae6c8193a2bb9b2a69fe1c0440399f38d94b3a0f1b447275a29978a'));
      expect(hex.encode(tree.root), hex.encode(root));

      var proof_0 = tree.getProof(leaf: leaves[0]);

      expect(
          tree.verify(proof: proof_0, targetNode: leaves[0], root: root), true);
    });

    test('sha3 - hex strings', () {
      var leaves = ['a', 'b', 'c']
          .map((x) => Uint8List.fromList(x.codeUnits))
          .map((x) => sha3(x))
          .toList();
      var tree = MerkleTree(leaves: leaves, hashAlgo: sha256);
      var root =
          '311d2e46f49b15fff8b746b74ad57f2cc9e0d9939fda94387141a2d3fdf187ae';
      expect(hex.encode(tree.root), root);
    });

    test('sha256 - no leaves', () {
      var leaves = <Uint8List>[];
      var tree = MerkleTree(leaves: leaves, hashAlgo: sha256);
      expect(hex.encode(tree.root), '');
    });

    test('sha256 - 1,000,000 leaves', () {
      var values = <String>[];
      for (var i = 0; i < 1e6; i++) {
        values.add('${i}');
      }

      var leaves = values
          .map((x) => Uint8List.fromList(x.codeUnits))
          .map((x) => sha256(x))
          .toList();

      var tree = MerkleTree(leaves: leaves, hashAlgo: sha256);

      var root =
          '101dd357df60384d254330fe118e3046871767c2748ebd62ce031c117df483da';
      expect(hex.encode(tree.root), root);
    }, skip: 'for benchmark only');
  });
}
