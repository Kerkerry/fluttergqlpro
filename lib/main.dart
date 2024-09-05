import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

final httpLink = HttpLink("https://fe9c-197-237-65-94.ngrok-free.app/graphql");

ValueNotifier<GraphQLClient> client =
    ValueNotifier(GraphQLClient(cache: GraphQLCache(), link: httpLink));

const String readStudent = """
    query student(\$ID: String!) {
        student(ID:\$ID) {
            id
            name
            age
        }
    }
""";
const String readStudents = """
  query students(){
    students{
      id
      name
      age
    }
  }
""";

const String addStudent = """
mutation addStudent(\$name:String!, \$age:Int!){
    addStudent(name:\$name,age:\$age){
        name,
        age
    }
}
""";

const String deleteStudent = """
  mutation deleteStudent(\$ID:String!){
    deleteStudent(ID:\$ID){
      id
      name
      age
    }
  }
""";

class Student {
  final String id;
  final String name;
  final int age;

  Student({required this.id, required this.name, required this.age});
}

class StudentModel extends Student {
  StudentModel({required super.id, required super.name, required super.age});

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(id: map['id'], name: map['name'], age: map['age']);
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Graphql Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Query(
            options: QueryOptions(
                document: gql(readStudents),
                // variables: const {'ID': "66cf8c696fc310f40bad844d"},
                pollInterval: const Duration(seconds: 3)),
            builder: (result, {fetchMore, refetch}) {
              if (result.hasException) {
                return Text(result.exception.toString());
              }

              if (result.isLoading) {
                return const Text('Loading');
              }
              // final st = StudentModel.fromMap(result.data?['student']);
              List students = (result.data?['students'] as List)
                  .map((st) => StudentModel.fromMap(st))
                  .toList();

              return Card(
                margin: const EdgeInsets.all(20),
                child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              "Name: ${students[index].name}  Age: ${students[index].age}"),
                          const SizedBox(width: 15),
                          Mutation(
                            options: MutationOptions(
                              document: gql(deleteStudent),
                              update: (cache, result) => cache,
                              onCompleted: (data) => print(data),
                            ),
                            builder: (runMutation, result) {
                              return IconButton(
                                  onPressed: () {
                                    runMutation({"ID": students[index].id});
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ));
                            },
                          )
                        ],
                      );
                    }),
              );
            },
          ),
        ),
        floatingActionButton: Mutation(
          options: MutationOptions(
            document: gql(addStudent),
            update: (cache, result) => cache,
            onCompleted: (data) => print(data),
          ),
          builder: (runMutation, result) {
            return FloatingActionButton(
              onPressed: () {
                runMutation({'name': "Patella Omoto", 'age': 22});
              },
              child: const Icon(Icons.add),
            );
          },
        ));
  }
}
